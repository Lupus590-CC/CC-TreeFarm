-- TODO: add to snippets/random CC code github repo
local function argChecker(position, value, validTypesList, level)
  -- check our own args first, sadly we can't use ourself for this
  if type(position) ~= "number" then
    error("argChecker: arg[1] expected number got "..type(position),2)
  end
  -- value could be anything, it's what the caller wants us to check for them
  if type(validTypesList) ~= "table" then
    error("argChecker: arg[3] expected table got "..type(validTypesList),2)
  end
  if not validTypesList[1] then
    error("argChecker: arg[3] table must contain at least one element",2)
  end
  for k, v in ipairs(validTypesList) do
    if type(v) ~= "string" then
      error("argChecker: arg[3]["..tostring(k).."] expected string got "..type(v),2)
    end
  end
  if type(level) ~= "nil" and type(level) ~= "number" then
    error("argChecker: arg[4] expected number or nil got "..type(level),2)
  end
  level = level and level + 1 or 2

  -- check the client's stuff
  for k, v in ipairs(validTypesList) do
    if type(value) == v then
      return
    end
  end

  local expectedTypes
  if #validTypesList == 1 then
      expectedTypes = validTypesList[1]
  else
      expectedTypes = table.concat(validTypesList, ", ", 1, #validTypesList - 1) .. " or " .. validTypesList[#validTypesList]
  end

  error("arg["..position.."] expected "..expectedTypes
  .." got "..type(value), level)
end

local function tableChecker (positionInfo, tableToCheck, templateTable, rejectExtention, level)
end

_ENV.argChecker = argChecker
_ENV.tableChecker = tableChecker
