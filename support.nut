function string_contains(haystack, needle) {
    local needleLen = needle.len();
    local haystackLen = haystack.len();

    if (needleLen == 0 || haystackLen < needleLen) {
        return false;
    }

    for (local i = 0; i <= haystackLen - needleLen; ++i) {
        local found = true;
        for (local j = 0; j < needleLen; ++j) {
            if (haystack[i + j] != needle[j]) {
                found = false;
                break;
            }
        }
        if (found) {
            return true;
        }
    }

    return false;
}