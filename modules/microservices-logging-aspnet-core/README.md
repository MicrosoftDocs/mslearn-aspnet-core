# Update to .NET 6 


- As we don't want this module to overwrite the "live" branch and "linux-latest" dockerhub image directly, we made two changes:

    1. gitBranch specified as net6/release-microservices-logging-aspnet-core

    2. Helm deployment tags specified as linux-net6-coupon . 

    3. Includes docker-compose scripts to build & push it to dockerhub.


- Changes needed on course content:

    1. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-logging-aspnet-core/4-implement-app-insights

        pushd src/Services/Catalog/Catalog.API/ && \
            dotnet add package Microsoft.ApplicationInsights.AspNetCore --version 2.12.1 && \
            dotnet add package Microsoft.ApplicationInsights.Kubernetes --version 1.1.1 && \
            dotnet add package Serilog.Sinks.ApplicationInsights --version 3.1.0 && \
            popd

            to

        pushd src/Services/Catalog/Catalog.API/ && \
            dotnet add package Microsoft.ApplicationInsights.AspNetCore --version 2.20.0 && \
            dotnet add package Microsoft.ApplicationInsights.Kubernetes --version 2.0.2 && \
            dotnet add package Serilog.Sinks.ApplicationInsights --version 3.1.0 && \
            popd
	


    2. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-logging-aspnet-core/4-implement-app-insights

        deploy/k8s/deploy-application.sh --registry eshopdev --charts coupon,ordering

            to
        
        deploy/k8s/deploy-application.sh --registry eshoplearn --charts coupon,ordering
