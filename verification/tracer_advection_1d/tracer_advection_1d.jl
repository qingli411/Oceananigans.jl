using Printf
using OffsetArrays
using DifferentialEquations
using Plots

#####
##### Advection or flux-reconstruction schemes
#####

abstract type AbstractAdvectionScheme end

struct FirstOrderUpwind <: AbstractAdvectionScheme end
@inline ∂x_advective_flux(i, N, Δx, u, ϕ, ::FirstOrderUpwind) =
    max(u[i], 0) * (ϕ[i] - ϕ[i-1])/Δx + min(u[i], 0) * (ϕ[i+1] - ϕ[i])/Δx

struct SecondOrderCentered <: AbstractAdvectionScheme end
@inline advective_flux(i, N, u, ϕ, ::SecondOrderCentered) = u[i] * (ϕ[i-1] + ϕ[i]) / 2
@inline ∂x_advective_flux(i, N, Δx, u, ϕ, scheme) =
    (advective_flux(i+1, N, u, ϕ, scheme) - advective_flux(i, N, u, ϕ, scheme)) / Δx

#####
##### Forward Euler time-stepping of advection equation
#####

function advection!(∂ϕ∂t, ϕ, p, t)
    ϕ[0], ϕ[p.N+1] = ϕ[p.N], ϕ[1]  # Fill ghost points to enforce periodic boundary conditions.
    for i in 1:p.N
        ∂ϕ∂t[i] = ∂x_advective_flux(i, p.N, p.Δx, p.u, ϕ, p.scheme)
    end
end

#####
##### Initial conditions and analytic solutions
#####

# Convert x to periodic range in [-L/2, L/2] assuming u = 1.
@inline x′(x, t, L) = mod(x + L/2 - t, L) - L/2

# Analytic solutions
@inline ϕ_Gaussian(x, t, L; a=1, c=1/8) = a*exp(-x′(x, t, L)^2 / (2c^2))
@inline ϕ_Square(x, t, L; w=0.15) = -w <= x′(x, t, L) <= w ? 1.0 : 0.0

ic_name(::typeof(ϕ_Gaussian)) = "Gaussian"
ic_name(::typeof(ϕ_Square))   = "Square"

#####
##### Experiment functions
#####

function create_figure(N, L, CFL, ϕₐ, time_stepper, scheme)
    Δx = L/N
    x = range(-L/2 + Δx/2, L/2 - Δx/2; length=N)
    ϕ₀ = ϕₐ.(x, 0, L)

    u = OffsetArray(ones(N+2), 0:N+1)
    ϕ₀ = OffsetArray([0, ϕ₀..., 0], 0:N+1)

    T = 1.0  # one revolution end time
    Δt = CFL * Δx / maximum(abs, u)
    nt = ceil(T/Δt)

    tspan = (0.0, T)
    params = (N=N, Δx=Δx, u=u, scheme=scheme)
    prob = ODEProblem(advection!, ϕ₀, tspan, params)
    sol = solve(prob, time_stepper, adaptive=false, dt=Δt)
    ϕ = sol[:, end]

    @info "Solver return code: $(sol.retcode)"

    title = @sprintf("%s %s N=%d CFL=%.2f", typeof(scheme), typeof(time_stepper), N, CFL)
    ϕ_analytic = ϕₐ.(x, T, L)
    p = plot(x, ϕ_analytic, label="analytic", title=title, xlims=(-0.5, 0.5), ylims=(-0.2, 1.2), dpi=200)
    plot!(p, x, ϕ[1:N], label="numerical")

    fig_filename = @sprintf("%s_%s_%s_N%d_CFL%.2f.png", ic_name(ϕₐ), typeof(scheme), typeof(time_stepper), N, CFL)
    savefig(p, fig_filename)

    return nothing
end

function create_animation(N, L, CFL, ϕₐ, scheme)
    Δx = L/N
    x = range(-L/2 + Δx/2, L/2 - Δx/2; length=N)
    ϕ₀ = ϕₐ.(x, 0, L)

    u = OffsetArray(ones(N+2), 0:N+1)
    ϕ = OffsetArray([0, ϕ₀..., 0], 0:N+1)

    T = 2  # two revolutions end time
    Δt = CFL * Δx / maximum(abs, u)
    nt = ceil(T/Δt)

    function every(N)
         0 < N <= 16 && return 10
        16 < N <= 32 && return 2
        32 < N <= 64 && return 4
        64 < N       && return 8
    end

    anim = @animate for iter in 1:nt
        iter % 100 == 0 && @printf("iter = %d/%d\n", iter, nt)

        time_step_advection!(ϕ, u, N, Δx, Δt, scheme)

        title = @sprintf("%s N=%d CFL=%.2f", typeof(scheme), N, CFL)
        ϕ_analytic = ϕₐ.(x, nt*Δt, L)
        plot(x, ϕ_analytic, label="analytic", title=title, xlims=(-0.5, 0.5), ylims=(-0.2, 1.2), dpi=200)
        plot!(x, ϕ[1:N], label="$(typeof(scheme))")
    end every every(N)

    anim_filename = @sprintf("%s_%s_N%d_CFL%.2f.mp4", ic_name(ϕₐ), typeof(scheme), N, CFL)
    mp4(anim, anim_filename, fps = 30)

    return nothing
end

#####
##### Run 1D tracer advection experiments
#####

L = 1
ϕs = (ϕ_Gaussian,)
time_steppers = (Euler(), AB3(), CarpenterKennedy2N54())
schemes = (SecondOrderCentered(),)
Ns = [16, 32, 64, 128]
CFLs = [0.05, 0.3, 0.5, 0.9, 1.5, 2.0, 3.0, 4.0]

for ϕ in ϕs, ts in time_steppers, scheme in schemes, N in Ns, CFL in CFLs
    @info @sprintf("Creating one-revolution figure [%s, %s, %s, N=%d, CFL=%.2f]...", ic_name(ϕ), typeof(ts), typeof(scheme), N, CFL)
    create_figure(N, L, CFL, ϕ, ts, scheme)

    # @info @sprintf("Creating two-revolution animation [%s, N=%d, CFL=%.2f]...", typeof(scheme), N, CFL)
    # create_animation(N, L, CFL, ϕ, scheme)
end

