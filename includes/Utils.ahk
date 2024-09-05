ArraySearch(haystack, needle, default := -1)
{
    loop haystack.Length
    {
        if (haystack[A_Index] = needle)
        {
            return A_Index
        }
    }

    return default
}