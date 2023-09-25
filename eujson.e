
-- stringify(), parse()

namespace JSON

--include std/map.e
include std/search.e
public include std/get.e

function elementize_escape_chars(sequence st, sequence escape_chars = "\\tnr")
    -- done.
    integer pos
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
    integer start, pos
    pos = 0
    while pos < length(st) do
        pos = find('\"', st, pos + 1)
        if not pos then
            exit
        end if
        start = pos
        --loop do
            pos = find('\"', st, pos + 1)
            if not pos then
                return {GET_EOF, st} -- syntax error
            end if
            --until st[pos - 1] != '\\'
        --end loop
        st = replace(st, {st[start..pos]}, start, pos)
        pos = start + 1
    end while
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
    --trace(1)
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
                -- success
                s = get_contents(st[i + 1..pos - 1], delims)
                if s[1] != GET_SUCCESS then
                    return s
                end if
                st = replace(st, {delims[1][kind] & s[2] & delims[2][kind]}, i, pos)
                return {GET_SUCCESS, st}
                -- return {i, pos, kind, st[i..pos]}
            end if
            return {GET_EOF, st}
            --return {i, pos, kind}
        end if
        i += 1
    end while
    trace(1)
    return {GET_SUCCESS, st}
    --return {i, pos}
end function

function parse_json_objects_and_arrays(sequence st)
-- process all the nested containers (objects and arrays) first,
-- then go back and start at the top and process the content,
-- when there are no more containers to process.
    
--here.

    integer pos, ch, f, kind
    sequence a, ele, tmp, list, s = {}
    st = remove_whitespace(st)
    pos = 0
    while length(st) do
        a = get_contents(st, {"{[", "}]"})
        if length(a) < 4 then
            if length(a) < 3 then
                return {GET_SUCCESS, st}
            else
                exit
                -- return {GET_EOF, s}
            end if
        end if
        s = append(s, st[1..a[1]-1]) -- save "intro" to JSON
        st = st[a[2]+1..$] -- to be saved at the end
        -- kind = a[3] -- 1 or 2
        a = a[4] -- [2..$-1] -- delimitted tag.
        -- a = remove_whitespace(a)
        s = append(s, a)
    end while

--        pos = find_any("{[", st)
--        if pos then
--            ch = st[pos]
--            s = append(s, st[1..pos]) -- save "intro" to JSON
--            st = st[pos + 1..$]
--            st = remove_leading_whitespace(st)
--            list = {}
--            if ch = '{' then
--                -- JSON object:
--                pos = rfind('}', st)
--            else
--                -- JSON array:
--                pos = rfind(']', st)
--            end if
--            if not pos then
--                return {GET_FAIL, s}
--            end if
--            a = st[1..pos - 1]
--            st = st[pos..$] -- returns at the end.
--            a = remove_trailing_whitespace(a)
            trace(1)
            loop do
                pos = find(',', a)
                if not pos then
                    pos = length(a) + 1
                end if
                tmp = a[1..pos - 1] -- before the comma
                a = a[pos + 1..$] -- after the comma
                tmp = remove_trailing_whitespace(tmp)
                a = remove_leading_whitespace(a)
                if ch = '{' then
                    f = find(':', tmp)
                    if not f then
                        return {GET_FAIL, s}
                    end if
                    ele = tmp[1..f - 1] -- key part
                    tmp = tmp[f + 1..$] -- value part
                    ele = remove_trailing_whitespace(ele) & ':'
                end if
                tmp = parse_json_objects_and_arrays(tmp)
                if tmp[1] != GET_SUCCESS then
                    return tmp
                end if
                if ch = '{' then
                    tmp[1] = ele
                    tmp = tmp[1..2]
                else
                    tmp = tmp[2]
                end if
                list = append(list, tmp)
                until pos > length(a)
            end loop
        --end if
        s = s & st
    --end while
    return {GET_SUCCESS, s}
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

public function stringify(sequence obj)
    -- encode Euphoria object to JSON string.
    sequence json_string

    return json_string
end function
