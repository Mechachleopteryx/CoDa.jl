# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

"""
    CoDaArray(table)

Construct an array of compositional data from `table`.
"""
struct CoDaArray{D,PARTS} <: AbstractVector{Composition{D,PARTS}}
  data::Matrix{Union{Float64,Missing}}
end

function CoDaArray(table)
  parts = Tables.columnnames(table)
  data  = Tables.matrix(table, transpose=true)
  CoDaArray{length(parts),parts}(data)
end

Base.getindex(array::CoDaArray{D,PARTS}, i) where {D,PARTS} =
  Composition(PARTS, array.data[:,i])

Base.size(array::CoDaArray) = (size(array.data, 2),)

Base.IndexStyle(::Type{<:CoDaArray}) = IndexLinear()

"""
    parts(array)

Parts in compositional `array`.
"""
parts(::CoDaArray{D,PARTS}) where {D,PARTS} = PARTS

"""
    compose(table, cols; keepcols=false, as=:coda)

Convert columns `cols` of `table` into parts of a
composition and save the result in a [`CoDaArray`](@ref).
If `keepcols` is set to `true`, then save the result `as`
a column in a new table with all other columns preserved.

## Example

Create a compositional array from columns `(:Cd, :Cu, :Pb)`:

```julia
julia> compose(table, (:Cd, :Cu, :Pb))
```

Do the same operation, but this time place the array as a
column named `:coda` in a new table containing all other
columns in the original table:

```julia
julia> compose(table, (:Cd, :Cu, :Pb), keepcols = true)
```
"""
function compose(table, cols=Tables.columnnames(table);
                 keepcols=false, as=:coda)
  # construct compositional array from selected columns
  csel = TableOperations.select(table, cols...)
  ctab = Tables.columntable(csel) # see https://github.com/JuliaData/TableOperations.jl/issues/25
  coda = CoDaArray(ctab)

  # different types of return
  if keepcols
    other = setdiff(Tables.columnnames(table), cols)
    osel  = TableOperations.select(table, other...)
    ocol  = [o => Tables.getcolumn(osel, o) for o in other]
    # preserve input table type
    𝒯 = Tables.materializer(table)
    𝒯((; ocol..., as => coda))
  else
    coda
  end
end

# -----------------
# TABLES INTERFACE
# -----------------

# implement table interface for CoDaArray
Tables.istable(::Type{<:CoDaArray}) = true
Tables.rowaccess(::Type{<:CoDaArray}) = true
Tables.rows(array::CoDaArray) = array

# implement row interface for Composition
Tables.getcolumn(c::Composition, i::Int)    = getfield(c, :data)[i]
Tables.getcolumn(c::Composition, n::Symbol) = getfield(c, :data)[n]
Tables.columnnames(c::Composition{D,PARTS}) where {D,PARTS} = PARTS