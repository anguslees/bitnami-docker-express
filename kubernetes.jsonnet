// This expects to be run with:
//  jsonnet -J <path to ksonnet-lib> -V APP_IMAGE=myrepo/myapp:mytag
local k = import "ksonnet.beta.2/k.libsonnet";

local deployment = k.extensions.v1beta1.deployment;

local container = deployment.mixin.spec.template.spec.containersType;
local containerPort = container.portsType;
local service = k.core.v1.service;
local servicePort = service.mixin.spec.portsType;

local myappImage = std.extVar("APP_IMAGE");

local mongodbContainer =
  container.new("mongodb", "bitnami/mongodb:latest");

local mongodbDeploy =
  deployment.new("mongodb", 1, [mongodbContainer], {service: "mongodb"});

local myappContainer =
  container.new("myapp", myappImage) +
  container.mixin.livenessProbe.httpGet.port(3000) +
  container.mixin.livenessProbe.httpGet.path("/");

local myappDeploy =
  deployment.new("myapp", 1, [myappContainer], {service: "myapp"});

local mongodbService =
  service.new("mongodb", mongodbDeploy.spec.template.metadata.labels, servicePort.new(27017, 27017));

local myappService =
  service.new("myapp", myappDeploy.spec.template.metadata.labels, servicePort.new(3000, 3000)) +
  service.mixin.spec.type("LoadBalancer");

{
  mongodbService: mongodbService,
  mongodbDeploy: mongodbDeploy,
  myappService: myappService,
  myappDeploy: myappDeploy,
}
