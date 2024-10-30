import logging

from datetime import datetime, timezone

class AgentPoolHandler:
    jobs_per_agent = 5
    cooldown_minutes = 5

    def __init__(self, client, resource_group_name, acr_name, agent_pool_name):
        self.client = client
        self.resource_group_name = resource_group_name
        self.acr_name = acr_name
        self.agent_pool_name = agent_pool_name

    def get_runs(self):
        runs = []
        for run in self.client.runs.list(self.resource_group_name, self.acr_name):
            runs.append(run)

        return runs
    
    def get_new_pool_size(self):
        queue = self.client.agent_pools.get_queue_status(self.resource_group_name, self.acr_name, self.agent_pool_name)
        pool = self.client.agent_pools.get(self.resource_group_name, self.acr_name, self.agent_pool_name)
        logging.info('Current queue size: %s', queue.count)
        logging.info('Current pool size: %s', pool.count)

        if queue.count > 0 and pool.count == 0 or pool.count * self.jobs_per_agent < queue.count:
            return pool.count + 1

        runs = self.get_runs()
        pool_runs = [run for run in runs if run.agent_pool_name == self.agent_pool_name]
        active_runs = [run for run in pool_runs if run.status == 'Started' or run.status == 'Running']
        logging.info('Active runs: %s', active_runs)

        if len(active_runs) == 0 and pool.provisioning_state == 'Succeeded' and pool.count > 0:
            cooldown_elapsed = min((datetime.now(timezone.utc) - pool_runs[0].finish_time).microseconds, (datetime.now(timezone.utc) - pool.system_data.last_modified_at).microseconds)
            logging.info("Cooldown elapsed is %s seconds", (cooldown_elapsed/1000))
            if (self.cooldown_minutes * 60 * 1000) < cooldown_elapsed:
                logging.info("Cooldown elapsed.")
                return pool.count - 1
            logging.info("Agent pool still on cooldown.")

        return None
    
    def scale_pool(self, size):
        logging.info('Scaling pool to %s instances', size)
        if self.client.agent_pools.get(self.resource_group_name, self.acr_name, self.agent_pool_name).provisioning_state == 'Succeeded':
            self.client.agent_pools.begin_update(self.resource_group_name, self.acr_name, self.agent_pool_name,{"count": str(size)}).result()
            logging.info('Update succeeded.')
        logging.info('Canceled operation, due to agent pool being in a updating state.')
