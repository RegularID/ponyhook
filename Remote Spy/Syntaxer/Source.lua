local Syntaxer = {}

local Lexer = Import("Syntaxer/init")


function Syntaxer:Highlight(TextObject, String)
    return Lexer.Highlight(TextObject, String)
end


return Syntaxer