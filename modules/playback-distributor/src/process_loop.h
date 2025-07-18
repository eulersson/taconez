// Copyright 2024 Ramon Blanquer Ruiz
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/**
 * @brief Process Loop for the Detector Messages.
 *
 * This function is invoked every time a message is received from the
 * detector. The function processes the incoming message and notifies
 * the connected players to play the detected sound.
 *
 * @param pull_socket The socket to receive messages from the detector.
 * @param push_socket The socket to send messages to the players.
 * @return 0 on success, -1 on failure
 */
int process_loop(void *pull_socket, void *push_socket);
