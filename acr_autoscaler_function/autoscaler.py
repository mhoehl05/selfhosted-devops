import os
import logging

from azure.identity import DefaultAzureCredential
from azure.mgmt.containerregistry import ContainerRegistryManagementClient

from agentPoolHandler import AgentPoolHandler

class Autoscaler:
    def run():

        SUBSCRIPTION_ID = os.environ.get("SUBSCRIPTION_ID")
        GROUP_NAME = os.environ.get("GROUP_NAME")
        REGISTRIES = os.environ.get("REGISTRIES")
        AGENT_POOL = os.environ.get("AGENT_POOL")

        containerregistry_client = ContainerRegistryManagementClient(
            credential=DefaultAzureCredential(),
            subscription_id=SUBSCRIPTION_ID,
            api_version="2019-06-01-preview"
        )

        agent_pool_handler = AgentPoolHandler(
            containerregistry_client, 
            GROUP_NAME, 
            REGISTRIES,
            AGENT_POOL
        )

        logging.info('Found %s runs.', len(agent_pool_handler.get_runs()))
        new_size = agent_pool_handler.get_new_pool_size()
        if new_size != None:
            logging.info('New pool size should be %s', new_size)
            agent_pool_handler.scale_pool(new_size)
        else:
            logging.info('No need to scale.')
