# Update to .NET 6 


- As we don't want this module to overwrite the "live" branch and "linux-latest" dockerhub image directly, we made two changes:

    1. gitBranch specified as configuration-net6-latest

    2. Helm deployment tags specified as linux-net6-coupon and linux-net6-feature-flags . 

    3. Includes docker-compose scripts to build & push it to dockerhub.


- Changes needed on course content:

    1. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-configuration-aspnet-core/4-implement-feature-management

        pushd src/Web/WebSPA && \
            dotnet add package Microsoft.FeatureManagement.AspNetCore --version 2.2.0 && \
            popd
            
        to
            
        pushd src/Web/WebSPA && \
            dotnet add package Microsoft.FeatureManagement.AspNetCore --version 2.5.1 && \
            popd
            


    2. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-configuration-aspnet-core/4-implement-feature-management

        pushd src/Web/WebSPA && \
            dotnet add package Microsoft.Azure.AppConfiguration.AspNetCore --version 4.0.0 && \
            popd
            
        to
            
        pushd src/Web/WebSPA && \
            dotnet add package Microsoft.Azure.AppConfiguration.AspNetCore --version 5.0.0 && \
            popd
