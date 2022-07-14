using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Microsoft.Extensions.Configuration
{
    public static class IConfigurationExtensions
    {
        public static bool UseFeatureManagement(this IConfiguration configuration) => 
            configuration["UseFeatureManagement"] == bool.TrueString;
    }
}
