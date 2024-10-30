import azure.functions as func
import json
import logging

from datetime import datetime, timezone
from autoscaler import Autoscaler

app = func.FunctionApp()

@app.function_name(name="AcrAgentAutoscaler")
@app.timer_trigger(schedule="*/20 * * * * *", 
              arg_name="AcrAgentAutoscaler",
              run_on_startup=True) 
def acr_agent_function(AcrAgentAutoscaler: func.TimerRequest) -> None:
    utc_timestamp = datetime.now(timezone.utc).replace(
        tzinfo=timezone.utc).isoformat()
    if AcrAgentAutoscaler.past_due:
        logging.info('The timer is past due!')

    Autoscaler.run()
    
    logging.info('Python ACR autoscaler function ran at %s', utc_timestamp)