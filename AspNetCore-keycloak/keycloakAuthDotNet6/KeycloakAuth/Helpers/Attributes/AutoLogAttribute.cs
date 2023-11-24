using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Logging;


/// <summary>
/// <see cref="https://learn.microsoft.com/en-us/aspnet/core/mvc/controllers/filters#Dependency injection"/>
/// </summary>
public class AutoLogAttribute : TypeFilterAttribute
    {
        public AutoLogAttribute() : base(typeof(AutoLogActionFilterImpl))
        {

        }

        private class AutoLogActionFilterImpl : IActionFilter
        {
            private readonly ILogger _logger;
            public AutoLogActionFilterImpl(ILoggerFactory loggerFactory)
            {
                _logger = loggerFactory.CreateLogger<AutoLogAttribute>();
            }

            public void OnActionExecuting(ActionExecutingContext context)
            {
                // perform some business logic work
            }

            public void OnActionExecuted(ActionExecutedContext context)
            {
                //TODO: log body content and response as well
                _logger.LogDebug($"path: {context.HttpContext.Request.Path}"); 
                _logger.LogDebug($"body: {context.HttpContext.Request.Body}"); 
                _logger.LogDebug($"response: {context.HttpContext.Response}");
            }
        }
    }