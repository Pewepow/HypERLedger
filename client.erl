-module(client).
-import('lists', [append/2]).
-import('string', [join/2]).
-import('main', []).
-export([init/0,
         init/1, 
        help/1,
        login/1, 
        choose/1, 
        registerClient/1, 
        sendMoney/2,
        printBlockchain/1,
        printList/1]).

% ====================================================================================================== %
%                                   Client Application to interact with                                  %
%                                       the hypERLedger blockchain                                       %
% ====================================================================================================== %


% ======================================
% Init functions to start the client App
% with or without arguments
% ======================================

init() ->
    {ok, Ca_Host} = io:read("Please provide the host name of the Central Authority:\n=> "),
    clr(),
    Pid = spawn(?MODULE, choose, [Ca_Host]),
    register(client, Pid),
    loop().

init(Ca_Host) ->
    clr(),
    Pid = spawn(?MODULE, choose, [Ca_Host]),
    register(client, Pid),
    loop().


% ======================================
% Make sure that init() doesnt stop
% running 
% ======================================
loop() ->
    timer:sleep(10000),
    loop().

% ======================================
% Choose what to do 
% ======================================

choose(Ca_Host) ->
    printLine(),
    io:format("hypERLedger CLIENT APPLICATION"),
    printLine(),
    io:format("1. Create new account~n"),
    io:format("2. Log in~n"),
    io:format("3. Print Blockchain~n"),
    io:format("4. Help~n"),
    io:format("5. Quit~n"),

    {ok, Choice} = io:read("=> "),
    case Choice of
        1 ->
            clr(),
            registerClient(Ca_Host);
        2 ->
            clr(),
            login(Ca_Host);
        3 ->
            clr(),
            printBlockchain(Ca_Host);
        4 ->
            clr(),
            help(Ca_Host);
        5 ->
            io:format("EXITING~n"),
            clr(),
            exit(self(), ok);
        _ ->
            clr(),
            choose(Ca_Host)
    end,
    io:format("Loading...").

% ======================================
% Help page
% ======================================

help(Ca_Host) ->
    printLine(),
    io:format("GENERAL INSTRUCTIONS"),
    printLine(),
    io:format("~p~n", [node()]),
    io:format("- If there is a choice with numbers, type in the correct number and hit ENTER~n"),
    io:format("- If you have to type in a string of characters, make sure to end with a period~n"),
    io:format("- You need to first create an account before being able to login~n"),
    io:format("- Make sure to never loose your Secret Name, as this is the only way to enter your wallet~n"),
    io:format("- To recieve hypercoins retrieve your Public Address from inside your wallet and give that address to the sender~n"),
    io:format("1. Back~n"),
    {ok, Choice} = io:read("=> "),
    case Choice of
        1 ->
            choose(Ca_Host);
        _ ->
            clr(),
            help(Ca_Host)
    end.



% ======================================
% Register Client with a new secret name
% ======================================
registerClient(Ca_Host) ->
    printLine(),
    io:format("REGISTER CLIENT"),
    printLine(),
    {ok, SecretName} = io:read("Type in a secret name for your new account (or \"1\" to go back): "),
    case SecretName of
        1 ->
            choose(Ca_Host);
        _ ->
            {ca, Ca_Host}  ! {client, node(), register, SecretName},
            receive
                {ca, ok} ->
                    clr(),
                    io:format("Success! You may now log in~n"),
                    login(Ca_Host);
                {ca, nope, M} ->
                    clr(),
                    io:format("WARNING: Something went wrong creating your account~n"),
                    io:format("WARNING: ~s", [M]),
                    choose(Ca_Host)
                after 2000 ->
                    timeout(),
                    choose(Ca_Host)
            end
    end.    

% ======================================
% Login to Wallet 
% ======================================
login(Ca_Host) ->
    printLine(),
    io:format("LOGIN"),
    printLine(),
    io:format("INFO: Make sure no one is looking over your shoulder...~n"),
    {ok, SecretName} = io:read("Type in your secret name to enter your wallet (or the number \"1\" to go back): "),
    case SecretName of 
        1 ->
            clr(),
            choose(Ca_Host);
        _ ->
            % Try logging in with secret name
            {ca, Ca_Host}! {client, node(), login, SecretName},
            % Wait for answer from CA
            receive 
                {ca, ok} ->
                    wallet(SecretName, Ca_Host);
                {ca, nope} ->
                    io:format("WARNING: No match found for ~p. Please make sure it's spelled correctly~n", [SecretName]),
                    login(Ca_Host)
                after 2000 ->
                    timeout(),
                    choose(Ca_Host)
            end
    end.

% ======================================
% Print Blockchain
% ======================================
printBlockchain(Ca_Host) ->
    printLine(),
    io:format("Overview of all Transactions"),
    printLine(),

    {ca, Ca_Host} ! {client, node(), printChain},
    receive
        {ca, ok, ChainData} ->
            printList(ChainData)
    end,
    io:format("1. Back~n"),
    {ok, Answer} = io:read("=> "),
    case Answer of
        1 ->
            clr(),
            choose(Ca_Host);
        _ ->
            clr(),
            printBlockchain(Ca_Host)
    end.

% ======================================
% Personal Wallet
% ======================================

wallet(From, Ca_Host) ->
    clr(),
    printLine(),
    io:format("~p's WALLET", [From]),
    printLine(),
    io:format("1. Retrieve Account Balance~n"),
    io:format("2. Show Public Address~n"),
    io:format("3. Send Money~n"),
    io:format("4. Logout~n"),
    io:format("5. Quit~n"),
    
    {ok, Choice} = io:read("=> "),
    case Choice of
        1 ->
            clr(),
            retrieveBalance(From, Ca_Host);
        2 ->
            clr(),
            publicAddress(From, Ca_Host);
        3 ->
            clr(),
            sendMoney(From, Ca_Host);
        4 ->
            clr(),
            choose(Ca_Host);
        5 ->    
           io:format("QUITTING~n"),
           exit(self(), ok);
        _ ->
            clr(),
            wallet(From, Ca_Host)
    end.

% ======================================
% Retrieving Account Balance
% ======================================

retrieveBalance(From, Ca_Host) ->
    printLine(),
    io:format("ACCOUNT BALANCE"),
    printLine(),
    {ca, Ca_Host} ! {client, node(), retrieveBalance, From},
    receive
        {ca, ok, Balance} ->
            io:format("~p~n", [Balance]);
        {ca, nope} ->
            io:format("Problem retrieving account balance~n")
    end,
    io:format("1. Back~n"),
    {ok, Choice} = io:read(""),
    case Choice of
        1 ->
            wallet(From, Ca_Host);
        _ ->
            clr(),
            retrieveBalance(From, Ca_Host)
    end.

% ======================================
% Show public address
% ======================================
publicAddress(SecretName, Ca_Host) ->
    printLine(),
    io:format("Public Address"),
    printLine(),

    {ca, Ca_Host} ! {client, node(), retrievePAddr, SecretName},
    receive
        {ca, PublicAddress} ->
            io:format("~s~n", [PublicAddress])
        after 2000 ->
            ca_unreachable()
    end,
    io:format("1. Back~n"),
    {ok, Choice} = io:read(""),
    case Choice of
        1 ->
            wallet(SecretName, Ca_Host);
        _ ->
            clr(),
            publicAddress(SecretName, Ca_Host)
    end.


% ======================================
% Sending Money to another account
% ======================================
sendMoney(From, Ca_Host) ->
    printLine(),
    io:format("TRANSACTION ZONE"),
    printLine(),
    io:format("1. New Transaction~n"),
    io:format("2. Back~n"),
    {ok, Choice} = io:read("=> "),
    case Choice of
        1 ->
            newTransaction(From, Ca_Host);
        2 ->
            wallet(From, Ca_Host);
        _ ->
            clr(),
            sendMoney(From, Ca_Host)
    end.

% ======================================
% Create a new Transaction 
% ======================================
newTransaction(From, Ca_Host) ->
    clr(),
    printLine(),
    io:format("TRANSACTION ZONE"),
    printLine(),
    {ok, To} = io:read("Who do you want to send hyperCoins to?  "),
    {ok, Amount} = io:read("How many hyperCoins do you want to send?  "),
    io:format("~nWARNING: You are about to send ~p hyperCoins to ~w~n", [Amount, To]),
    io:format("Type ok to proceed, no to correct your transaction or quit to stop everything~n"),
    {ok, Answer} = io:read("=> "),
    case Answer of
        ok ->
            {ca, Ca_Host} ! {client, node(), From, To, Amount};
        no ->
            clr(),
            sendMoney(From, Ca_Host);
        quit ->
            io:format("EXITING~n"),
            clr(),
            exit(self(), ok);
        _ ->
            clr(),
            newTransaction(From, Ca_Host)
    end,
    receive
        {ca, ok, Message} ->
            printLine(),
            io:format("~s~n", [Message]),
            io:format("Transaction complete~n"),
            io:format("Bye Bye Hypercoins"),
            printLine();
        {ca, nope, Message} ->
            printLine(),
            io:format("Transaction failed, please retry~n"),
            io:format("~s", [Message]),
            printLine()
    end,
    sendMoney(From, Ca_Host).

% ======================================
% Helper Functions
% ======================================
printLine() ->
    io:format("~n================================================================~n").

clr() ->
    io:format("\e[H\e[J").

printList([]) ->
    io:format("~n");

printList(List) ->
    [H|T] = List,
    {{From, To, Amount, NSFrom, NSTo}, Hash} = H,
    io:format("___________________________________________________~n~n"),
    io:format("From:~p~nTo: ~p~nAmount: ~w~nNew Balance Sender: ~w~nNew Balance Receiver: ~w~nBlock Hash: ~p~n~n", [From, To, Amount, NSFrom, NSTo, Hash]),
    printList(T).

% ======================================
% Error Functions
% ======================================
timeout() ->
   io:format("~nA timeout occured, redirecting...~n").

ca_unreachable() ->
   io:format("~nCentral Authority unreachable...~n").

