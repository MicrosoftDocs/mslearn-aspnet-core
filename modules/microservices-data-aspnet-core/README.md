# Update to .NET 6 


- As we don't want this module to overwrite the "live" branch and "linux-latest" dockerhub image directly, we made two changes:

    1. gitBranch specified as net6/release-microservices-data-aspnet-core

    2. Helm deployment tags specified as linux-net6-latest . 


- Changes needed on course content:

    1. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-data-aspnet-core/implement-azure-cache

        On "Configure the basket service to use the new Azure Cache for Redis instance" section:

        On file signalr/templates/configmap.yaml

            SignalrStoreConnectionString: basketdata

            to your variation of

            SignalrStoreConnectionString: eshop-redis-202104230000.redis.cache.windows.net:6380,password=[password],ssl=True,abortConnect=False

    2. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-data-aspnet-core/implement-cosmos-db

        deploy/k8s/deploy-application.sh --charts coupon --registry eshopdev

            to

        deploy/k8s/deploy-application.sh --charts coupon --registry eshoplearn

        *ecortijo instead of eshoplearn when testing using my dockerhub
            