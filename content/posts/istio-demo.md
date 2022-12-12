---
title: "Istio Demo"
author: "Jijun Dai"
date: 2022-12-10T02:35:45-05:00
draft: true
categories:
- istio
tags:
- istio
- k8s
---

## Istio demo

```shell
  $  curl -L https://istio.io/downloadIstio | sh -
  $  echo 'export PATH="$PATH:/home/packer/istio-1.15.0/bin"' >> ~/.bashrc
  $  export PATH="$PATH:/home/packer/istio-1.15.0/bin"
  $  istioctl x precheck
  $  istioctl install --set profile=demo -y
  $  k label ns devops istio-injection=enabled
  
  $  k get ns
  $  cd istio-1.15.0/
  $  kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
  $  k get pod -n istio-system
  $  kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}'
  $  kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
  
  $  kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
  $  istioctl analyze
  $  k get all -n istio-system
  $  kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  $  kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
  $  kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}'
  $  kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}'
  
  $  kubectl apply -f samples/addons
  $  kubectl rollout status deployment/kiali -n istio-system

  # spin up kiali UI locally
  $  istioctl dashboard kiali
  
  $  kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
  $  export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  $  export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io
  $  echo $INGRESS_DOMAIN
 # set up gateway for kiali 
  $  cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kiali-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http-kiali
      protocol: HTTP
    hosts:
    - "kiali.${INGRESS_DOMAIN}"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kiali-vs
  namespace: istio-system
spec:
  hosts:
  - "kiali.${INGRESS_DOMAIN}"
  gateways:
  - kiali-gateway
  http:
  - route:
    - destination:
        host: kiali
        port:
          number: 20001
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: kiali
  namespace: istio-system
spec:
  host: kiali
  trafficPolicy:
    tls:
      mode: DISABLE
---
EOF

  $  k get gateways.networking.istio.io  -n istio-system
  $  k describe gateways.networking.istio.io -n istio-system kiali-gateway
  $  k get gateways.networking.istio.io -n istio-system kiali-gateway -o yaml > kiali-istio-gateway.yaml
  
  # open http://$INGRESS_DOMAIN/kiali in a browser to check the Graph tab
  $  echo $INGRESS_DOMAIN
  # generate trafic to access the productpage service
  $  for i in $(seq 1 100); do curl -s -o /dev/null "http://$INGRESS_DOMAIN/productpage"; done
  $  for i in $(seq 1 1000); do curl -s -o /dev/null "http://$INGRESS_DOMAIN/productpage"; done
```

### Manually istio injection
`$ kubectl apply -f < (istioctl kube-inject -f path/to/yaml/file.yaml`
