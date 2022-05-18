# Update to .NET 6 


- As we don't want this module to overwrite the "live" branch and "linux-latest" dockerhub image directly, we made two changes:
    
    1. gitBranch specified as microservices-aspnet-core-net6-final

    2. Helm deployment tags specified as linux-net6-initial . 
    
    3. Includes docker-compose scripts to build & push it to dockerhub.


- Changes needed on course content:

    1. In page: https://docs.microsoft.com/en-us/learn/modules/microservices-aspnet-core/6-add-coupon-service

        "dotnet build src/Services/Coupon/Coupon.API/" failed because it was detecting old dotnet version (I have more than one installed). 
        In order to fix it, I had to do this (suggested here https://docs.microsoft.com/en-us/answers/questions/203560/cloud-shell-it-was-not-possible-to-find-any-compat.html  )
            export PATH="~/.dotnet:$PATH"
            echo "export PATH=~/.dotnet:\$PATH" >> ~/.bashrc
            
    2. In page: https://docs.microsoft.com/en-us/learn/modules/microservices-aspnet-core/6-add-coupon-service
        "./deploy/k8s/build-to-acr.sh" needs to be changed to "./deploy/k8s/build-to-acr.sh --services coupon-api,webspa"