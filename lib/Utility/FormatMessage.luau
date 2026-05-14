--!strict

--[[
    A utility module for formatting error and warning messages consistently across the Vluxy Sound Factory. This module provides functions to create standardized error messages, throw errors, and issue warnings, ensuring that all messages related to the sound system are easily identifiable and informative for developers.
]]
local FormatMessage = {}

--[[
    Creates a standardized error message by prefixing it with the module name.

    @param errorMessage any - The specific error message to be formatted.

    @return any - The formatted error message with the module prefix.
]]
function FormatMessage.NewMessage(errorMessage: any): any
	return "[VluxySF]: " .. errorMessage
end

--[[
    Throws an error with a formatted message.

    This function uses the `error` function to throw an error with a standardized message format, making it easier for developers to identify that the error is related to the Vluxy Sound Factory.

    @param errorMessage any - The specific error message to be thrown.
    @param level number? - Optional parameter to specify the stack level for the error (default is 1).
]]
function FormatMessage.Error(errorMessage: any, level: number?)
	error(FormatMessage.NewMessage(errorMessage), level or 2)
end

--[[
    Creates a thunk (a function that can be called later) for throwing an error with a formatted message.

    @param errorMessage any - The specific error message to be thrown when the thunk is called.
    @param level number? - Optional parameter to specify the stack level for the error (default is 1).

    @return (number?) -> () - A function that, when called, will throw an error with the formatted message. The caller can optionally provide a different stack level when invoking the thunk.
]]
function FormatMessage.ErrorThunk(errorMessage: any, level: number?): (number?) -> ()
	return function(levelOverride: number?)
		FormatMessage.Error(errorMessage, levelOverride or level or 3)
	end
end

--[[
    Issues a warning with a formatted message.

    This function uses the `warn` function to issue a warning with a standardized message format, making it easier for developers to identify that the warning is related to the Vluxy Sound Factory.

    @param warningMessage any - The specific warning message to be issued.
]]
function FormatMessage.Warn(warningMessage: any)
	warn(FormatMessage.NewMessage(warningMessage))
end

--[[
    Creates a thunk (a function that can be called later) for issuing a warning with a formatted message.

    @param warningMessage any - The specific warning message to be issued when the thunk is called.

    @return () -> () - A function that, when called, will issue a warning with the formatted message.
]]
function FormatMessage.WarnThunk(warningMessage: any): () -> ()
	return function()
		FormatMessage.Warn(warningMessage)
	end
end

--[[
    Prints a formatted message to the console.

    This function uses the `print` function to output a message with a standardized format, making it easier for developers to identify that the message is related to the Vluxy Sound Factory.

    @param message any - The specific message to be printed.
]]
function FormatMessage.Print(message: any)
	print(FormatMessage.NewMessage(message))
end

--[[
    Creates a thunk (a function that can be called later) for printing a formatted message.

    @param message any - The specific message to be printed when the thunk is called.

    @return () -> () - A function that, when called, will print a message with the formatted format.
]]
function FormatMessage.PrintThunk(message: any): () -> ()
	return function()
		FormatMessage.Print(message)
	end
end

return FormatMessage
