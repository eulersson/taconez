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

#ifndef PROCESS_LOOP_H
#define PROCESS_LOOP_H

/**
 * @brief Process Loop for Distributor Messages
 *
 * This function is invoked every time a message is received from the
 * distributor. The function processes the incoming message and performs
 * the necessary actions based on the message content.
 *
 * @param sub_socket The socket to receive messages from the distributor
 * @return 0 on success, -1 on failure
 */
int process_loop(void *sub_socket);

#endif
