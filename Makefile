SNOWFLAKE_REPO?=sfseeurope-sfseeurope-eu-demo376.registry.snowflakecomputing.com/spcs_app/napp/img_repo
BACKEND_IMAGE=eap_backend
FRONTEND_IMAGE=eap_frontend
ROUTER_IMAGE=eap_router
ACCOUNT_URL=sfseeurope-sfseeurope-eu-demo376.registry.snowflakecomputing.com
SS_DB=SPCS_APP
SS_SCHEMA=NAPP
SS_STAGE=APP_STAGE
ROLE=naspcs_role


help:            ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

all: login build push upload_app_files list_stage_file

# login:           ## Login to Snowflake Docker repo
# 	docker login $(SNOWFLAKE_REPO)


upload_app_files: ## upload yaml to stage $(SS_STAGE)
	snow stage copy --role $(ROLE) na_spcs_python/v2/ @$(SS_DB).$(SS_SCHEMA).$(SS_STAGE)/na_spcs_python/v2/

list_stage_file:
	snow stage list-files --role $(ROLE) @$(SS_DB).$(SS_SCHEMA).$(SS_STAGE)

login:
	snow spcs image-registry token --format=JSON | docker login $(ACCOUNT_URL) -u 0sessiontoken --password-stdin

build: build_backend build_frontend build_router  ## Build Docker images for Snowpark Container Services

build_backend:   ## Build Docker image for backend for Snowpark Container Services
	cd backend && docker build --platform linux/amd64 -t $(BACKEND_IMAGE) . && cd ..

build_frontend:  ## Build Docker image for frontend for Snowpark Container Services
	cd frontend && docker build --platform linux/amd64 -t $(FRONTEND_IMAGE) . && cd ..

build_router:    ## Build Docker image for router for Snowpark Container Services
	cd router && docker build --platform linux/amd64 -t $(ROUTER_IMAGE) . && cd ..

push: push_backend push_frontend push_router     ## Push Docker images to Snowpark Container Services

push_backend:    ## Push backend Docker image to Snowpark Container Services
	docker tag $(BACKEND_IMAGE) $(SNOWFLAKE_REPO)/$(BACKEND_IMAGE)
	docker push $(SNOWFLAKE_REPO)/$(BACKEND_IMAGE)

push_frontend:   ## Push frontend Docker image to Snowpark Container Services
	docker tag $(FRONTEND_IMAGE) $(SNOWFLAKE_REPO)/$(FRONTEND_IMAGE)
	docker push $(SNOWFLAKE_REPO)/$(FRONTEND_IMAGE)

push_router:     ## Push router Docker image to Snowpark Container Services
	docker tag $(ROUTER_IMAGE) $(SNOWFLAKE_REPO)/$(ROUTER_IMAGE)
	docker push $(SNOWFLAKE_REPO)/$(ROUTER_IMAGE)
