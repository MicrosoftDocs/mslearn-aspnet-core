# Update to .NET 6 


- As we don't want this module to overwrite the "live" branch and "linux-latest" dockerhub image directly, we made two changes:
    
    1. gitBranch specified as net6/release-microservices-resiliency-aspnet-core

    2. Helm deployment tags specified as linux-net6-coupon . 
    
    3. Includes docker-compose scripts to build & push it to dockerhub.


- Changes needed on course content:

    1. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-resiliency-aspnet-core/5-implement-polly-resiliency

        dotnet add package Microsoft.Extensions.Http.Polly --version 3.1.6 

            to

        dotnet add package Microsoft.Extensions.Http.Polly --version 6.0.5


    2. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-resiliency-aspnet-core/6-implement-linkerd-resiliency

        ./deploy/k8s/deploy-application.sh --registry eshopdev --charts webshoppingagg 

        to

        ./deploy/k8s/deploy-application.sh --registry eshoplearn --charts webshoppingagg

        *ecortijo instead of eshoplearn when testing using my dockerhub


    3. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-resiliency-aspnet-core/6-implement-linkerd-resiliency

        ./deploy/k8s/deploy-application.sh --registry eshopdev --charts apigateway,coupon,webshoppingagg 

        to 

        ./deploy/k8s/deploy-application.sh --registry eshoplearn --charts apigateway,coupon,webshoppingagg

        *ecortijo instead of eshoplearn when testing using my dockerhub
