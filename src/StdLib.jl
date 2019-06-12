module StdLib

using ..CxxWrap

abstract type CppBasicString <: AbstractString end

function append end
function cppsize end
function resize end

@wrapmodule(CxxWrap.libcxxwrap_julia_stl)

function __init__()
  @initcxx
end

# Pass-through for fundamental types
_append_dispatch(v::StdVector,a::Vector,::Type{CxxWrap.IsNormalType}) = append(v,a)
# For C++ types, convert the array to an array of references, so the pointers can be read directly from a contiguous array on the C++ side
_append_dispatch(v::StdVector{T}, a::Vector{<:T},::Type{CxxWrap.IsCxxType}) where {T} = append(v,CxxWrap.CxxRef.(a))
# Choose the correct append method depending on the type trait
append(v::StdVector{T}, a::Vector{<:T}) where {T} = _append_dispatch(v,a,CxxWrap.cpp_trait_type(T))

Base.ncodeunits(s::CppBasicString)::Int = cppsize(s)
Base.codeunit(s::StdString) = UInt8
Base.codeunit(s::StdWString) = Cwchar_t == Int32 ? UInt32 : UInt16
Base.codeunit(s::CppBasicString, i::Integer) = convert(Char, s[i])
Base.isvalid(s::CppBasicString, i::Integer) = (0 < i <= ncodeunits(s))
function Base.iterate(s::CppBasicString, i::Integer=1)
  if !isvalid(s,i)
    return nothing
  end
  return(codeunit(s,i),i+1)
end

function StdWString(s::String)
  char_arr = transcode(Cwchar_t, s)
  StdWString(char_arr, length(char_arr))
end

function _stdvector_ctor_dispatch(v::Vector{T}, ::Type) where {T}
  result = StdVector{T}()
  append(result, v)
  return result
end

function _stdvector_ctor_dispatch(v::Vector{T}, ::Type{CxxWrap.IsCxxType}) where {T}
  result = isconcretetype(T) ? StdVector{supertype(T)}() : StdVector{T}()
  append(result, v)
  return result
end

function StdVector(v::Vector{T}) where {T}
  return _stdvector_ctor_dispatch(v, CxxWrap.cpp_trait_type(T))
end

function StdVector(v::Vector{Bool})
  result = StdVector{Cuchar}()
  append(result, convert(Vector{Cuchar}, v))
  return result
end

Base.IndexStyle(::Type{<:StdVector}) = IndexLinear()
Base.size(v::StdVector) = (Int(cppsize(v)),)

function Base.push!(v::StdVector, x)
  push_back(v, x)
  return v
end

function Base.resize!(v::StdVector, n::Integer)
  resize(v, n)
  return v
end

Base.empty!(v::StdVector) = Base.resize!(v, 0)

function Base.append!(v::StdVector, a::Vector)
  append(v, a)
  return v
end

function Base.append!(v::StdVector{Cuchar}, a::Vector{Bool})
  append(v, convert(Vector{Cuchar}, a))
  return v
end

# Make sure functions taking a C++ string as argument can also take a Julia string
CxxWrap.map_julia_arg_type(x::Type{<:StdString}) = AbstractString

end