using Microsoft.AspNetCore.Http;

namespace ADSOLUSOL.Presentation.Api.Middleware;

public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    public ExceptionMiddleware(RequestDelegate next) => _next = next;
    public async Task InvokeAsync(HttpContext context) => await _next(context);
}
