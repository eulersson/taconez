import argparse

# Import it before using the `logging` module, so it can be configured.
from sound_detector import inference, retrain
from sound_detector.config import config
from sound_detector.exceptions import TaconezException

import logging

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Sound detector")

    subparsers = parser.add_subparsers(dest="command")

    parser_inference = subparsers.add_parser("inference")

    # TODO: Include specific arguments for inference `parser_inference.add_argument('--flag', ...)`

    parser_retrain = subparsers.add_parser("retrain")

    # TODO: Include specific arguments for retrain `parser_retrain.add_argument('--flag', ...)`

    args = parser.parse_args()

    if args.command:
        config.print_config()

    if args.command == "inference":
        inference.run_loop()

    elif args.command == "retrain":
        if config.use_tflite:
            raise TaconezException(
                "You cannot retrain the model when using TFLite mode since `USE_TFLITE` "
                "would imply not installing the TensorFlow libraries and only the TFLite "
                "runtime instead."
            )
        retrain.run()

    else:
        parser.print_help()
        exit(1)
