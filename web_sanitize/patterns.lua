local P, R, S, C, Cp, Ct, Cg, Cc, Cs
do
  local _obj_0 = require("lulpeg")
  P, R, S, C, Cp, Ct, Cg, Cc, Cs = _obj_0.P, _obj_0.R, _obj_0.S, _obj_0.C, _obj_0.Cp, _obj_0.Ct, _obj_0.Cg, _obj_0.Cc, _obj_0.Cs
end
local alphanum = R("az", "AZ", "09")
local num = R("09")
local hex = R("09", "af", "AF")
local at_most
at_most = function(p, n)
  assert(n > 0)
  if n == 1 then
    return p
  else
    return p * p ^ -(n - 1)
  end
end
local case_insensitive_word
case_insensitive_word = function(word)
  local pattern
  for char in word:gmatch(".") do
    local l = char:lower()
    local u = char:upper()
    local p
    if l == u then
      p = P(l)
    else
      p = S(tostring(l) .. tostring(u))
    end
    if pattern then
      pattern = pattern * p
    else
      pattern = p
    end
  end
  return pattern
end
local escaped_html_char = S("<>'&\"") / {
  [">"] = "&gt;",
  ["<"] = "&lt;",
  ["&"] = "&amp;",
  ["'"] = "&#x27;",
  ["/"] = "&#x2F;",
  ['"'] = "&quot;"
}
local escaped_html_tag_char = S("<>'&\"") / {
  [">"] = "&gt;",
  ["<"] = "&lt;"
}
local escape_html_text = Cs((escaped_html_char + 1) ^ 0 * -1)
local escape_attribute_text = Cs((escaped_html_tag_char + 1) ^ 0 * -1)
local white = S(" \t\n") ^ 0
local word = (alphanum + S("._-")) ^ 1
local attribute_value = C(word) + P('"') * C((1 - P('"')) ^ 0) * P('"') + P("'") * C((1 - P("'")) ^ 0) * P("'")
local attribute_name = (alphanum + S("._-:")) ^ 1
local tag_attribute = Ct(C(attribute_name) * (white * P("=") * white * attribute_value) ^ -1)
local open_tag = Ct(Cg(Cp(), "pos") * P("<") * white * Cg(word, "tag") * Cg(Ct((white * tag_attribute) ^ 1), "attr") ^ -1 * white * ("/" * white * P(">") * Cg(Cc(true), "self_closing") + P(">")) * Cg(Cp(), "inner_pos"))
local close_tag = Cp() * P("<") * white * P("/") * white * C(word) * white * P(">")
local html_comment = P("<!--") * -P(">") * -P("->") * (P(1) - P("<!--") - P("-->") - P("--!>")) ^ 0 * P("<!") ^ -1 * P("-->")
local cdata = P("<![CDATA[") * (P(1) - P("]]>")) ^ 0 * P("]]>")
local begin_raw_text_tag
do
  local raw_text_tags
  raw_text_tags = require("web_sanitize.data").raw_text_tags
  local name_pats
  for _index_0 = 1, #raw_text_tags do
    local t = raw_text_tags[_index_0]
    local p = case_insensitive_word(t)
    if name_pats then
      name_pats = name_pats + p
    else
      name_pats = p
    end
  end
  begin_raw_text_tag = P("<") * white * name_pats * -alphanum
end
local begin_close_tag = P("<") * white * P("/") * white * C(word)
local MAX_UNICODE = 0x10FFFF
local translate_entity
translate_entity = function(str, kind, value)
  if kind == "named" then
    local entities = require("web_sanitize.html_named_entities")
    return entities[str] or entities[str:lower()] or str
  end
  local codepoint
  local _exp_0 = kind
  if "dec" == _exp_0 then
    codepoint = tonumber(value)
  elseif "hex" == _exp_0 then
    codepoint = tonumber(value, 16)
  end
  local utf8_encode
  utf8_encode = require("web_sanitize.unicode").utf8_encode
  if codepoint and codepoint <= MAX_UNICODE then
    return utf8_encode(codepoint)
  else
    return str
  end
end
local annoteted_html_entity = C(P("&") * (Cc("named") * at_most(alphanum, 20) + P("#") * (Cc("dec") * C(at_most(num, 10)) + S("xX") * Cc("hex") * C(at_most(hex, 5)))) * P(";") ^ -1)
local decode_html_entity = annoteted_html_entity / translate_entity
local unescape_html_text = Cs((decode_html_entity + P(1)) ^ 0)
return {
  alphanum = alphanum,
  tag_attribute = tag_attribute,
  open_tag = open_tag,
  close_tag = close_tag,
  begin_raw_text_tag = begin_raw_text_tag,
  html_comment = html_comment,
  cdata = cdata,
  attribute_name = attribute_name,
  decode_html_entity = decode_html_entity,
  unescape_html_text = unescape_html_text,
  escaped_html_char = escaped_html_char,
  escape_html_text = escape_html_text,
  escape_attribute_text = escape_attribute_text,
  case_insensitive_word = case_insensitive_word
}
