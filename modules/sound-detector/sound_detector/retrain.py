"""
Creates a new model from an existing one (YAMNet) and retrains it to detect high heels.
"""

import logging

from sound_detector.models.retrained import RetrainedModel

def run():
    logging.info("Running retrain...")
    
    retrained_model = RetrainedModel()
    retrained_model.build_and_retrain()
    retrained_model.initialize()