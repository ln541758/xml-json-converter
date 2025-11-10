"""
Locust load testing file for XML-JSON converter service.

This file provides load testing scenarios for the XML to JSON conversion API.
Run with: locust -f locustfile.py --host=http://localhost:8080
"""

from locust import HttpUser, task, between, events
import logging

# Sample XML data for POST requests
SAMPLE_XML = """<logs>
  <log><id>0</id><level>INFO</level><msg>Message 0</msg></log>
  <log><id>1</id><level>INFO</level><msg>Message 1</msg></log>
  <log><id>2</id><level>INFO</level><msg>Message 2</msg></log>
  <log><id>3</id><level>INFO</level><msg>Message 3</msg></log>
  <log><id>4</id><level>INFO</level><msg>Message 4</msg></log>
  <log><id>5</id><level>INFO</level><msg>Message 5</msg></log>
  <log><id>6</id><level>INFO</level><msg>Message 6</msg></log>
  <log><id>7</id><level>INFO</level><msg>Message 7</msg></log>
  <log><id>8</id><level>INFO</level><msg>Message 8</msg></log>
  <log><id>9</id><level>INFO</level><msg>Message 9</msg></log>
</logs>"""


class XMLConverterUser(HttpUser):
    """
    Simulates a user that sends XML conversion requests to the server via POST.
    
    This sends XML data in the POST request body and receives JSON response.
    
    Run: locust -f locustfile.py --host=http://localhost:8080 --users=100 --spawn-rate=100 --run-time=60s --headless
    
    This will spawn 100 users at once (spawn-rate=100) to hit the server simultaneously.
    """
    
    # Wait time between tasks (set to 0 for continuous load)
    wait_time = between(0, 0)
    
    @task
    def convert_xml(self):
        """
        Send XML data via POST request for conversion.
        The handler accepts POST with XML in the body, converts to JSON, and saves to S3.
        """
        headers = {"Content-Type": "application/xml"}
        with self.client.post(
            "/convert", 
            data=SAMPLE_XML.encode('utf-8'),
            headers=headers,
            catch_response=True
        ) as response:
            if response.status_code == 200:
                try:
                    # Verify we got JSON back
                    response.json()
                    response.success()
                except Exception as e:
                    response.failure(f"Invalid JSON response: {e}")
            else:
                response.failure(f"Failed with status code: {response.status_code}")


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Log when the test starts"""
    logging.info("Load test starting...")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Log test statistics when the test ends"""
    logging.info("Load test completed!")
    logging.info(f"Total requests: {environment.stats.total.num_requests}")
    logging.info(f"Total failures: {environment.stats.total.num_failures}")
    logging.info(f"Average response time: {environment.stats.total.avg_response_time:.2f}ms")
    logging.info(f"RPS: {environment.stats.total.total_rps:.2f}")

