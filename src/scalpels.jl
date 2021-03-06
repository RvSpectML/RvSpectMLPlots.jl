"""
Convenience code for plotting result of Scalpels

For algorithm information, see Collier-Cameron, Ford, Shahaf et al. 2020

Author: Eric Ford
Date:   September 2020
"""


function make_plots_scalpels(rvs::AbstractVector{T1}, ccfs::AbstractArray{T2,2}
                ; σ_rvs::AbstractVector{T3} = ones(length(rvs)),
                max_num_basis::Integer = 3,
                v_grid::AbstractRange = 1:size(ccfs,1),
                times::AbstractVector{T4} = collect(1:length(rvs)),
                output_path::String = "", save_fig::Bool = false ) where
                { T1<:Real, T2<:Real, T3<:Real, T4<:Real  }

    @assert length(rvs) == length(σ_rvs)
    @assert length(v_grid) == size(ccfs,1)
    @assert length(rvs) == size(ccfs,2)
    @assert 1 <= max_num_basis < length(rvs)

    mean_rv = mean(rvs, weights(1.0 ./ σ_rvs.^2 ))
    rvs_centered = rvs .- mean_rv

    ccfs_minus_mean = ccfs .- mean(ccfs,dims=2)
    zvals =ccfs_minus_mean
    colorscale = cgrad(:balance)

    acfs = autocor(ccfs,0:size(ccfs,1)-1)
    acfs_minus_mean = acfs .- mean(acfs,dims=2)
    Δv_grid = convert(Float64,v_grid.step).*(0:size(acfs,1)-1)
    zvals = acfs_minus_mean
    heatmap(Δv_grid, 1:size(acfs,2),zvals',c=colorscale, clims=(-maximum(abs.(zvals)),maximum(abs.(zvals))) )
    title!("ACF(δv)-<ACF(δv)>")
    xlabel!("Δv (m/s)")
    ylabel!("Obs #")
    if save_fig
        savefig(output_path * "acf_heatmap.png")
    end

    svd_ccfs = svd(ccfs_minus_mean')
    plot(v_grid,svd_ccfs.V[:,1:max_num_basis])
    title!("CCF(v) basis functions")
    xlabel!("v (m/s)")
    if save_fig
        savefig(output_path * "ccf_basis.png")
    end

    svd_acfs = svd(acfs_minus_mean')
    plot(Δv_grid,svd_acfs.V[:,1:max_num_basis])
    title!("ACF(v) basis functions")
    xlabel!("Δv (m/s)")
    if save_fig
        savefig(output_path  * "acf_basis.png")
    end

    alpha = svd_acfs.U'*rvs_centered
    idx = sortperm(abs.(alpha),rev=true)
    local rvs_clean, plt
    for num_basis in 1:max_num_basis
        U_keep = view(svd_acfs.U,:,idx[1:num_basis])
        Δrv_shape = U_keep*U_keep'*rvs_centered
        rvs_clean = rvs .- Δrv_shape
        plt = scatter(times,rvs, label="RVs orig")
        scatter!(plt, times,rvs_clean, label="RVs cleaned", legend=:bottomright)
        xlabel!("Time (d)")
        ylabel!("RV (m/s)")
        title!("Cleaning RVs via Scalpels (" * string(num_basis) * " basis vectors)")
        if save_fig
            savefig( output_path * "scalpels_rvs_" * string(num_basis) * ".png")
        end
    end
    return plt
end
