
-- stringify(), parse()
-- use "map()" for associative array

namespace JSON

include std/map.e
include std/search.e
public include std/get.e

--with trace

function elementize_escape_chars(sequence st, sequence escape_chars = "\\\'\"tnr")
    -- done.
    integer pos, f
    sequence ret
    pos = 1
    while pos <= length(st) do
        f = find(st[pos], "\"0123456789-+")
        if f then
            ret = value(st, pos, GET_LONG_ANSWER)
            if ret[1] != GET_SUCCESS then
                return ret
            end if
            if atom(ret[2]) then
                st = st[1..pos - 1] & ret[2] & st[pos + ret[3]..$]
            else
                st = replace(st, {"\"" & ret[2] & "\""}, pos, pos + ret[3] - 1)
            end if
        end if
        pos += 1
    end while
    pos = 1
    while pos < length(st) do
        pos = find('\\', st, pos)
        if not pos then
            exit
        end if
        pos += 1
        if find(st[pos], escape_chars) then
            st = replace(st, {st[pos - 1..pos]}, pos - 1, pos)
        else
            return {GET_FAIL, st}
        end if
        pos += 1
    end while
    return {GET_SUCCESS, st}
end function

function elementize_strings(sequence st)
    -- done.
    sequence data = {"null", "true", "false"}
    integer start--, pos
--    start = 0
--    while start < length(st) do
--        start = find('\"', st, start + 1)
--        if not start then
--            exit
--        end if
--        pos = find('\"', st, start + 1)
--        if not pos then
--            return {GET_EOF, st} -- syntax error
--        end if
--        st = replace(st, {st[start..pos]}, start, pos)
--    end while
    for i = 1 to length(data) do
        start = 0
        while start < length(st) do
            start = match(data[i], st, start + 1)
            if not start then
                exit
            end if
            st = st[1..start - 1] & {data[i]} & st[start + length(data[i])..$]
            start += length(data[i]) - 1
        end while
    end for
    return {GET_SUCCESS, st}
end function

function remove_leading_whitespace(sequence st, sequence whitespace = " \t\n\r")
    -- done.
    while length(st) and find(st[1], whitespace) do
        st = st[2..$]
    end while
    return st
end function

function remove_trailing_whitespace(sequence st, sequence whitespace = " \t\n\r")
    -- done.
    while length(st) and find(st[$], whitespace) do
        st = st[1..$-1]
    end while
    return st
end function

function remove_whitespace(sequence st, sequence whitespace = " \t\n\r")
    -- done.
    st = remove_leading_whitespace(st, whitespace)
    st = remove_trailing_whitespace(st, whitespace)
    return st
end function

function get_contents(sequence st, sequence delims = {"{[", "}]"})
    -- done.
    integer pos, i, kind
    sequence s
    pos = 0
    i = 1
    while i < length(st) do
        kind = find(st[i], delims[1])
        if kind then
            pos = find(delims[1][kind], st, i + 1)
            if pos then
                s = get_contents(st[pos..$], delims)
                if s[1] != GET_SUCCESS then
                    return s
                end if
                st = st[1..pos - 1] & s[2]
                s = {}
            end if
            pos = find(delims[2][kind], st, i + 1)
            if pos then
                s = get_contents(st[i + 1..pos - 1], delims)
                if s[1] != GET_SUCCESS then
                    return s
                end if
                st = replace(st, {delims[1][kind] & s[2] & delims[2][kind]}, i, pos)
                return {GET_SUCCESS, st}
            end if
            return {GET_EOF, st}
        end if
        i += 1
    end while
    return {GET_SUCCESS, st}
end function

function parse_json_objects_and_arrays(sequence st)
-- process all the nested containers (objects and arrays) first,
-- then go back and start at the top and process the content,
-- when there are no more containers to process.
    --here.
    integer p = 1, i, f, flag
    object x
    sequence ret
    while p <= length(st) do
        x = st[p]
        if sequence(x) then
            -- do recursion
            i = 1
            while i <= length(x) do
                if atom(x[i]) then
                    x[i] = {x[i]}
                end if
                ret = parse_json_objects_and_arrays(x[i])
                x[i] = ret[2]
                if length(x[i]) = 0 then
                    x = x[1..i - 1] & x[i + 1..$]
                else
                    i += 1
                end if
            end while
            st[p] = x
        else
            f = find(x, "{[}]\n\r\t ")
            if f then
                -- remove whitespace
                st = st[1..p - 1] & st[p + 1..$]
            end if
            if f = 1 then
                
            end if

            if x = ':' then
                -- add to map
                flag = 1
            end if
        end if
        p += 1
    end while
    
    return {GET_SUCCESS, st}
end function

public function parse(sequence json_string)
    -- parse JSON string to Euphoria object (key:value pairs)

    sequence s
    s = elementize_escape_chars(json_string)
    if s[1] != GET_SUCCESS then
        return s
    end if
    s = elementize_strings(s[2])
    if s[1] != GET_SUCCESS then
        return s
    end if
    s = get_contents(s[2])
    if s[1] != GET_SUCCESS then
        return s
    end if
    s = parse_json_objects_and_arrays(s[2])
    if s[1] != GET_SUCCESS then
        return s
    end if

    return s
end function

/*
public function stringify(sequence obj)
    -- encode Euphoria object to JSON string.
    sequence json_string

    return json_string
end function
*/
