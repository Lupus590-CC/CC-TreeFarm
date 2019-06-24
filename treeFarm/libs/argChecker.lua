-- TODO: add to snippets/random CC code github repo #homeOnly
local function argCheckerFunc(position, value, validTypesList, level)
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

local function tableCheckerFunc(positionInfo, tableToCheck, templateTable, rejectExtention, level)
  argChecker(1, positionInfo, {"string"})
 argChecker(2, tableToCheck, {"table"})
 argChecker(3, templateTable, {"table"})
 argChecker(4, allowExtention, {"boolean", "nil"})
 argChecker(5, level, {"number", "nil"})

 level = level and level + 1 or 2

 local hasElements = false
 for k, v in pairs(templateTable) do
   hasElements = true
   if type(v) ~= "table" then
     error("arg["..3.."]["..tostring(k).."] expected table got "..type(v),2)
   end
   for k2, v2 in pairs(v) do
     if type(v2) ~= "string" then
       error("arg["..3.."]["..tostring(k).."]["..tostring(k2).."] expected string got "..type(v2),2)
     end
   end
 end
 if not hasElements then
   error("arg["..3.."] table must contain at least one element",2)
 end


 local function elementIsValid(element, validTypesList)
   for k, v in ipairs(validTypesList) do
     if type(element) == v then
       return true
     end
   end
   return false
 end

 -- check the client's stuff
 for key, value in pairs(tableToCheck) do
   if (rejectExtention) and (not templateTable[key]) then
     error(positionInfo.." table has invalid key "..tostring(key), level)
   end

   local validTypesList = templateTable[key]
   if not elementIsValid(value, validTypesList) then
     local expectedTypes
     if #validTypesList == 1 then
         expectedTypes = validTypesList[1]
     else
         expectedTypes = table.concat(validTypesList, ", ", 1, #validTypesList - 1) .. " or " .. validTypesList[#validTypesList]
     end

     error(positionInfo.."["..key.."] expected "..expectedTypes
     .." got "..type(value), level)
   end
 end

 for k, v in pairs(templateTable) do
   if not tableToCheck[k] then
     error("arg["..position.."] table is missing key "..tostring(k), level)
   end
 end
end


-- TODO: this doesn't work? #homeOnly
ENV.argChecker = argCheckerFunc
ENV.tableChecker = tableCheckerFunc


local this = {
  argChecker = argChecker,
  tableChecker = tableChecker,
}



return this
