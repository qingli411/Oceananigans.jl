#####
##### Centered second-order advection scheme
#####

"""
    struct CenteredSecondOrder <: AbstractAdvectionScheme{0}

Centered second-order advection scheme.
"""
struct CenteredSecondOrder{CA} <: AbstractAdvectionScheme{0} 
    "advection scheme used near boundaries"
    boundary_scheme :: CA
end

CenteredSecondOrder() = CenteredSecondOrder(nothing)

boundary_buffer(::CenteredSecondOrder) = 0

const C2 = CenteredSecondOrder
const centered_second_order = C2()

@inline advective_momentum_flux_Uu(i, j, k, grid, ::C2, U, u) = ℑxᶜᵃᵃ(i, j, k, grid, Ax_qᶠᶜᶜ, U) * ℑxᶜᵃᵃ(i, j, k, grid, u)
@inline advective_momentum_flux_Vu(i, j, k, grid, ::C2, V, u) = ℑxᶠᵃᵃ(i, j, k, grid, Ay_qᶜᶠᶜ, V) * ℑyᵃᶠᵃ(i, j, k, grid, u)
@inline advective_momentum_flux_Wu(i, j, k, grid, ::C2, W, u) = ℑxᶠᵃᵃ(i, j, k, grid, Az_qᶜᶜᶠ, W) * ℑzᵃᵃᶠ(i, j, k, grid, u)

@inline advective_momentum_flux_Uv(i, j, k, grid, ::C2, U, v) = ℑyᵃᶠᵃ(i, j, k, grid, Ax_qᶠᶜᶜ, U) * ℑxᶠᵃᵃ(i, j, k, grid, v)
@inline advective_momentum_flux_Vv(i, j, k, grid, ::C2, V, v) = ℑyᵃᶜᵃ(i, j, k, grid, Ay_qᶜᶠᶜ, V) * ℑyᵃᶜᵃ(i, j, k, grid, v)
@inline advective_momentum_flux_Wv(i, j, k, grid, ::C2, W, v) = ℑyᵃᶠᵃ(i, j, k, grid, Az_qᶜᶜᶠ, W) * ℑzᵃᵃᶠ(i, j, k, grid, v)

@inline advective_momentum_flux_Uw(i, j, k, grid, ::C2, U, w) = ℑzᵃᵃᶠ(i, j, k, grid, Ax_qᶠᶜᶜ, U) * ℑxᶠᵃᵃ(i, j, k, grid, w)
@inline advective_momentum_flux_Vw(i, j, k, grid, ::C2, V, w) = ℑzᵃᵃᶠ(i, j, k, grid, Ay_qᶜᶠᶜ, V) * ℑyᵃᶠᵃ(i, j, k, grid, w)
@inline advective_momentum_flux_Ww(i, j, k, grid, ::C2, W, w) = ℑzᵃᵃᶜ(i, j, k, grid, Az_qᶜᶜᶠ, W) * ℑzᵃᵃᶜ(i, j, k, grid, w)

@inline symmetric_interpolate_xᶜᵃᵃ(i, j, k, grid, ::C2, u) = ℑxᶜᵃᵃ(i, j, k, grid, u)
@inline symmetric_interpolate_xᶠᵃᵃ(i, j, k, grid, ::C2, c) = ℑxᶠᵃᵃ(i, j, k, grid, c)

@inline symmetric_interpolate_yᵃᶜᵃ(i, j, k, grid, ::C2, v) = ℑyᵃᶜᵃ(i, j, k, grid, v)
@inline symmetric_interpolate_yᵃᶠᵃ(i, j, k, grid, ::C2, c) = ℑyᵃᶠᵃ(i, j, k, grid, c)

@inline symmetric_interpolate_zᵃᵃᶜ(i, j, k, grid, ::C2, w) = ℑzᵃᵃᶜ(i, j, k, grid, w)
@inline symmetric_interpolate_zᵃᵃᶠ(i, j, k, grid, ::C2, c) = ℑzᵃᵃᶠ(i, j, k, grid, c)

# Calculate the flux of a tracer quantity c through the faces of a cell.
# In this case, the fluxes are given by u*Ax*c̄ˣ, v*Ay*c̄ʸ, and w*Az*c̄ᶻ.
@inline advective_tracer_flux_x(i, j, k, grid, ::C2, U, c) = Ax_qᶠᶜᶜ(i, j, k, grid, U) * ℑxᶠᵃᵃ(i, j, k, grid, c)
@inline advective_tracer_flux_y(i, j, k, grid, ::C2, V, c) = Ay_qᶜᶠᶜ(i, j, k, grid, V) * ℑyᵃᶠᵃ(i, j, k, grid, c)
@inline advective_tracer_flux_z(i, j, k, grid, ::C2, W, c) = Az_qᶜᶜᶠ(i, j, k, grid, W) * ℑzᵃᵃᶠ(i, j, k, grid, c)
