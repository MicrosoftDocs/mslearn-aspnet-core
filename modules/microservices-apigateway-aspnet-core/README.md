# Update to .NET 6 


- As we don't want this module to overwrite the "live" branch and "linux-latest" dockerhub image directly, we made two changes:

    1. gitBranch specified as net6/microservices-apigateway-aspnet-core

    2. Helm deployment tags specified as linux-net6-coupon . 


- Changes needed on course content:

    1. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-apigateway-aspnet-core/implement-bff

        For Section "Verify the deployed aggregator". Curl is not available in our pods. So we'll do it on a different way:

        1. Retrieve the cluster IP address of the websalesagg pod:

        kubectl get svc --selector service=websalesagg

        2. Deploy and open a shell on a new pod with a curl image

        kubectl run mycurlpod --image=curlimages/curl -i --tty -- sh

        3. Within the pod, use cURL to verify that the service is listening. Use the IP address that you retrieved earlier.

        curl http://<clusterip-of-websalesagg-pod>/websalesagg/swagger/index.html

        4. Use the following command to close the shell:

        exit

    2. On page: https://docs.microsoft.com/en-us/learn/modules/microservices-apigateway-aspnet-core/implement-azure-application-gateway

        deploy/k8s/deploy-application.sh --registry eshopdev --hostip {appgw-public-ip}

        to

        deploy/k8s/deploy-application.sh --registry eshoplearn --hostip {appgw-public-ip}

        ecortijo instead of eshoplearn when testing using my dockerhub

	

