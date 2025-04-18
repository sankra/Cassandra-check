import sys
import os
import subprocess
import time
import logging

from datetime import datetime, timedelta
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from cassandra import ConsistencyLevel
from cassandra.query import BatchStatement


for i in range(1, 4):
    try:
        # Connect to the Cassandra cluster
        cluster = Cluster(['AnaplanTransfromr1'], port=9042)
        session = cluster.connect('anaplan')
        logging.info("Connected to Cassandra cluster")
        break
    except Exception as e:
        logging.error(f"Failed to connect to Cassandra cluster: {e}")
        time.sleep(5)

