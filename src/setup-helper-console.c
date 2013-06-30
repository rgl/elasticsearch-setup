/* Windows Setup Helper functions.
 *
 * Copyright (c) 2011, Rui Lopes (ruilopes.com)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *   * Neither the name of Redis nor the names of its contributors may be used
 *     to endorse or promote products derived from this software without
 *     specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "setup-helper.c"
#include <stdio.h>

#define SERVICE_ACCOUNT_NAME L"elasticsearch"
#define SERVICE_ACCOUNT_PASSWORD L"B0d_Pa$$w0rd!*"
#define SERVICE_ACCOUNT_DESCRIPTION L"elasticsearch service"


static void show_help() {
	printf("available commands:\n\n");
	printf("create-account\n");
	printf("  create the `elasticsearch' account and assign the `log on as a service right'.\n");
	printf("\n");
	printf("destroy-account\n");
	printf("  destroy the `elasticsearch' account, respective rights and profile.\n");
}


static int create_account() {
    int error = ServiceAccountExists(SERVICE_ACCOUNT_NAME);

    if (!error) {
    	printf("ERROR did not create the account because it already exists.\n");
    	return -1;
    }

	int result = CreateServiceAccount(SERVICE_ACCOUNT_NAME, SERVICE_ACCOUNT_PASSWORD, SERVICE_ACCOUNT_DESCRIPTION);

	if (result != 0) {
		printf("ERROR failed to create account with result=%d\n", result);
		return -1;
	}

	printf("DONE.\n");
	return 0;
} 


static int delete_account() {
    int error = ServiceAccountExists(SERVICE_ACCOUNT_NAME);

    if (error) {
    	printf("WARN did not destroy the account because it does not exists.\n");
    	return -1;
    }

	int result = DestroyServiceAccount(SERVICE_ACCOUNT_NAME);

	if (result != 0) {
		printf("ERROR failed to remove account with result=%d\n", result);
		return -1;
	}

	printf("DONE.\n");
	return 0;
} 


int main(int argc, char *argv[]) {
	if (argc == 2 && strcmp(argv[1], "create-account") == 0) {
		return create_account();
	}

	if (argc == 2 && strcmp(argv[1], "destroy-account") == 0) {
		return delete_account();
	}

	show_help();
	return -1;
}
