using System;
using System.Collections.Generic;
using System.Net.Mime;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.FeatureManagement;

namespace WebSPA.Infrastructure.Middlewares
{
    public class FeatureManagementMiddleware
    {
        private static readonly JsonSerializerOptions _serializerOptions = new JsonSerializerOptions()
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            DictionaryKeyPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = false
        };

        const string FEATURENAME_QUERY_PARAMETER_NAME = "featureName";
        const string DEFAULT_MIME_TYPE = MediaTypeNames.Application.Json;
        
        private readonly RequestDelegate _next;
        
        public FeatureManagementMiddleware(RequestDelegate next)
        {
            _next = next ?? throw new ArgumentNullException(nameof(next));
        }

        public async Task Invoke(HttpContext context, IFeatureManager featureManager)
        {
            var evaluationsResponse = new List<EvaluationResponse>();

            var featureNames = context.Request
                .Query[FEATURENAME_QUERY_PARAMETER_NAME];

            foreach (var featureName in featureNames)
            {
                var isEnabled = await featureManager
                        .IsEnabledAsync(featureName);

                evaluationsResponse.Add(new EvaluationResponse()
                {
                    Name = featureName,
                    Enabled = isEnabled
                });
            }
            await WriteResponse(context, evaluationsResponse);
        }

        private async Task WriteResponse(HttpContext currentContext, IEnumerable<EvaluationResponse> response)
        {
            await WriteAsync(
                currentContext,
                JsonSerializer.Serialize(response, options: _serializerOptions),
                DEFAULT_MIME_TYPE,
                StatusCodes.Status200OK);
        }

        private async Task WriteAsync(
           HttpContext context,
           string content,
           string contentType,
           int statusCode)
        {
            context.Response.Headers["Content-Type"] = new[] { contentType };
            context.Response.Headers["Cache-Control"] = new[] { "no-cache, no-store, must-revalidate" };
            context.Response.Headers["Pragma"] = new[] { "no-cache" };
            context.Response.Headers["Expires"] = new[] { "0" };
            context.Response.StatusCode = statusCode;

            await context.Response.WriteAsync(content);
        }

        private class EvaluationResponse
        {
            public bool Enabled { get; set; }
            public string Name { get; set; }
        }
    }
}