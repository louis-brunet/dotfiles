#!/usr/bin/env python3

import argparse
import os
import select
import signal
import socket
import sys
import threading
import datetime
from typing import Optional

BUFFER_SIZE = 1 << 15  # 1 << k == 2 ** k
CONNECTION_QUEUE_SIZE = 5
LLAMA_SERVER_PORT = 8081
MAX_CONCURRENT_CONNECTIONS = 2


def log(*args) -> None:
    ansi_bold_blue = "\x1b[1;34m"
    ansi_grey = "\x1b[2;37m"
    ansi_reset = "\x1b[0m"
    timestamp = datetime.datetime.now().isoformat()
    prefix = f"{ansi_bold_blue}[INFO]{ansi_reset} {ansi_grey}{timestamp}{ansi_reset}"

    print(prefix, *args, sep=" ", flush=True)

# class TcpProxy:
#     def __init__(
#         self,
#         listen_host: str,
#         listen_port: int,
#         target_host: str,
#         target_port: int,
#         max_concurrent_connections: int,
#     ):
#         self.listen_host = listen_host
#         self.listen_port = listen_port
#         self.target_host = target_host
#         self.target_port = target_port
#         self.stop_accepting_connections = False
#         self.thread_count_semaphore = threading.Semaphore(max_concurrent_connections)
#
#     def start(self) -> None:
#         listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#         listen_socket.bind((self.listen_host, self.listen_port))
#         listen_socket.listen(CONNECTION_QUEUE_SIZE)
#
#         print(f"Listening on {self.listen_host}:{self.listen_port}")
#
#         while not self.stop_accepting_connections:
#             client_socket, client_address = listen_socket.accept()
#             print(f"Accepted connection from {client_address}")
#
#             self.thread_count_semaphore.acquire(blocking=True, timeout=None)
#
#             proxy_thread = threading.Thread(
#                 target=self._handle_client, args=(client_socket,)
#             )
#             proxy_thread.run()
#
#     # def stop(self):
#     #     self.stop_proxy_client = True
#
#     def _handle_client(self, client_socket: socket.socket) -> None:
#         BUFFER_SIZE = 1 << 15  # 1 << k == 2 ** k
#
#         with client_socket:
#             # Create a socket to connect to the target
#             with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as target_socket:
#                 target_socket.connect((self.target_host, self.target_port))
#
#                 sockets = [client_socket, target_socket]
#                 stop_proxy_thread = False
#                 while not stop_proxy_thread:
#                     s_read, _, _ = select.select(sockets, [], [])
#
#                     for s in s_read:
#                         data = s.recv(BUFFER_SIZE)
#
#                         if s == client_socket:
#                             # d = LOCAL_DATA_HANDLER(data)
#                             if not data:
#                                 target_socket.shutdown(socket.SHUT_RDWR)
#                                 target_socket.close()
#                                 stop_proxy_thread = True
#                                 break
#                             else:
#                                 target_socket.sendall(data)
#                         elif s == target_socket:
#                             # d = REMOTE_DATA_HANDLER(data)
#                             if not data:
#                                 client_socket.shutdown(socket.SHUT_RDWR)
#                                 client_socket.close()
#                                 stop_proxy_thread = True
#                                 break
#                             else:
#                                 client_socket.sendall(data)
#
#                 # target_socket.shutdown(socket.SHUT_RDWR)
#                 # target_socket.close()
#                 # client_socket.shutdown(socket.SHUT_RDWR)
#                 # client_socket.close()
#
#                 print(
#                     "Terminating proxy _handle_client thread (TODO: kill any child llama-server process created? probably not necessarily here)"
#                 )
#         self.thread_count_semaphore.release()
#
#     # def stop(self):
#     #     # Implement the logic to stop
#     #     pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Serve a model with `llama-server`.")

    parser.add_argument("--model-file", type=str, required=True)
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--host", type=str, default="127.0.0.1")
    parser.add_argument("--ctx-size", type=int, default=32768)
    parser.add_argument("--n-predict", type=int, default=64)
    parser.add_argument("--parallel", type=int, default=2)
    parser.add_argument("--prompt", type=str, default="")

    return parser.parse_args()


def start_llama_server(cmd: list[str]) -> int:
    # # nonlocal running_server_pid
    # if running_server_pid is None:
    child_server_id = os.fork()
    if child_server_id == 0:
        # NOTE: race condition on server port? if child has just been sent SIGTERM
        os.execvp("llama-server", cmd)
    else:
        log("STARTED llama-server child process, pid: {}".format(child_server_id))
        return child_server_id
    # return running_server_pid


def stop_llama_server_and_proxies(
    server_pid: Optional[int],
    proxy_pids: set[int],
    proxy_semaphore: threading.Semaphore,
) -> None:
    try:
        for child_proxy_pid in proxy_pids:
            log("stopping child proxy with pid {}".format(child_proxy_pid))
            os.kill(child_proxy_pid, signal.SIGTERM)
            # proxy_semaphore.release()
            # proxy_pids.remove(child_proxy_pid)
            log(
                f"There are now {MAX_CONCURRENT_CONNECTIONS - proxy_semaphore._value} connected clients"
            )
    # except Exception as e:
    #     log("ERROR [stop_llama_server_and_proxies] -", e)
    #
    # try:
        for child_proxy_pid in proxy_pids:
            pid_awaited, status_awaited = os.waitpid(child_proxy_pid, 0)
    except Exception as e:
        log("ERROR [stop_llama_server_and_proxies] -", e)

    try:
        if server_pid:
            log("stopping child server with pid {}".format(server_pid))
            os.kill(server_pid, signal.SIGTERM)
            pid_awaited, status_awaited = os.waitpid(server_pid, 0)
    except Exception as e:
        log("ERROR [stop_llama_server_and_proxies] -", e)




def main() -> None:
    """
    Start llama-server and proxy traffic. If the client closes the connection,
    then
    """

    def proxy_client_to_target(client_socket: socket.socket) -> None:
        try:
            with client_socket:
                # Create a socket to connect to the target
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as target_socket:
                    target_socket.connect(
                        (target_host, target_port),
                    )

                    sockets = [client_socket, target_socket]
                    stop_proxy_thread = False

                    while not stop_proxy_thread:
                        s_read, _, _ = select.select(sockets, [], [])

                        for s in s_read:
                            data = s.recv(BUFFER_SIZE)

                            if s == client_socket:
                                # d = LOCAL_DATA_HANDLER(data)
                                if not data:
                                    log("shutting down because CLIENT sent 0 data")
                                    # target_socket.shutdown(socket.SHUT_RDWR)
                                    # target_socket.close()
                                    # stop_proxy_thread = True
                                    # break

                                    target_socket.shutdown(socket.SHUT_WR)
                                    sockets.remove(client_socket)
                                    # client_socket.close()
                                else:
                                    target_socket.sendall(data)
                            elif s == target_socket:
                                # d = REMOTE_DATA_HANDLER(data)
                                if not data:
                                    log("shutting down because TARGET sent 0 data")

                                    if client_socket in sockets:
                                        client_socket.shutdown(socket.SHUT_RDWR)
                                        client_socket.close()
                                    stop_proxy_thread = True
                                    break
                                else:
                                    if client_socket in sockets:
                                        client_socket.sendall(data)
        except Exception as e:
            log("[proxy_client_to_target] ERROR -", e)
        finally:
            log("[proxy_client_to_target] done")
            # log("Terminating proxy proxy_client_to_target thread, releasing semaphore")
            # concurrent_clients_semaphore.release()
            # log(
            #     f"There are now {max_concurrent_connections - concurrent_clients_semaphore._value} connected clients"
            # )

    def sigchld_handler(signal, frame) -> None:
        try:
            while True:
                pid, status = os.waitpid(-1, os.WNOHANG)
                if pid == 0:
                    break
                log(f"SIGCHLD: child with pid {pid} has terminated")
                if pid in running_proxy_pids:
                    concurrent_clients_semaphore.release()
                    running_proxy_pids.remove(pid)
                    log(
                        f"There are now {MAX_CONCURRENT_CONNECTIONS - concurrent_clients_semaphore._value} connected clients"
                    )
        except Exception as e:
            log("ERROR [sigchld_handler] -", e)

    def sigint_handler(sig, frame) -> None:
        try:
            log(
                f"SIGINT: killing {len(running_proxy_pids)} proxy children and llama server with pid {running_server_pid}"
            )
            stop_llama_server_and_proxies(
                running_server_pid,
                running_proxy_pids,
                proxy_semaphore=concurrent_clients_semaphore,
            )
        except Exception as e:
            log("ERROR [sigint_handler] -", e)
        finally:
            log("Exiting...")
            sys.exit(0)

    args = parse_args()

    listen_port = args.port
    listen_host = args.host
    target_port = LLAMA_SERVER_PORT
    target_host = "127.0.0.1"

    server_cmd = [
        "llama-server",
        "--model",
        args.model_file,
        "--port",
        str(target_port),
        "--host",
        target_host,
        "--ctx-size",
        str(args.ctx_size),
        "--n-predict",
        str(args.n_predict),
        "--parallel",
        str(args.parallel),
        "--log-prefix",
        "--log-timestamps",
        "--prompt",
        args.prompt,
        # "--log-colors",
    ]
    running_server_pid: Optional[int] = start_llama_server(server_cmd)

    # running_server_pid: Optional[int] = None
    running_proxy_pids: set[int] = set()


    signal.signal(signal.SIGCHLD, sigchld_handler)
    signal.signal(signal.SIGINT, sigint_handler)

    listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listen_socket.bind((listen_host, listen_port))
    listen_socket.listen(CONNECTION_QUEUE_SIZE)

    concurrent_clients_semaphore: threading.Semaphore = threading.Semaphore(
        MAX_CONCURRENT_CONNECTIONS
    )
    log(f"server will be restarted if more than {MAX_CONCURRENT_CONNECTIONS} connections try to be established simultaneously")

    while True:
        log(f"Listening on {listen_host}:{listen_port}")
        client_socket, client_address = listen_socket.accept()
        log(f"Accepted connection from {client_address}")

        can_connect = concurrent_clients_semaphore.acquire(blocking=False, timeout=None)
        log(
            f"There are {MAX_CONCURRENT_CONNECTIONS - concurrent_clients_semaphore._value} connected clients"
        )

        if not can_connect:
            # assert (
            #     running_server_pid is not None
            # ), "Could not acquire semaphore but server is not yet running"
            log("Too many connections, restarting server and killing children.")
            stop_llama_server_and_proxies(
                server_pid=running_server_pid,
                proxy_pids=running_proxy_pids,
                proxy_semaphore=concurrent_clients_semaphore,
            )
            running_server_pid = start_llama_server(server_cmd)
            concurrent_clients_semaphore.acquire(blocking=True, timeout=None)

        proxy_child_pid = os.fork()
        if proxy_child_pid > 0:
            log(f"started proxy child with pid {proxy_child_pid}")
            running_proxy_pids.add(proxy_child_pid)
        else:
            proxy_client_to_target(client_socket)
            sys.exit(0)


if __name__ == "__main__":
    main()
