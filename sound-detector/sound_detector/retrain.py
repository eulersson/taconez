"""
Creates a new model from an existing one (YAMNet) and retrains it to detect high heels.
"""

import logging

def run():
    """
    Extract the embeddings from YAMNet model and use it as inputs to a model we create.
    Then train the new model with our labeled sound data under `sound-detector/dataset`.
    """
    logging.info("Running retrain...")