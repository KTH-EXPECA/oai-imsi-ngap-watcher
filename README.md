# Imsi-ngap-watcher for OpenAirInterface5G

Create the docker image and push
```
docker build -t samiemostafavi/imsi-ngap-watcher .
docker push samiemostafavi/imsi-ngap-watcher
```

Run it on the same machine as you run oai-amf
```
docker run -d --name imsi-ngap-watcher \
  -e AMF_CONTAINER=oai-amf \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp:/tmp \
  samiemostafavi/imsi-ngap-watcher
```

This will keep `/tmp/ngap_imsi_map.log` updated with lines like:
```
001010000000001 0x0D 0x65
001010000000005 0x21 0x02
```
meaning:
```
IMSI AMF_UE_NGAP_ID RAN_UE_NGAP_ID
```
For the UEs that are with `5GMM-REGISTERED` state in AMF.
