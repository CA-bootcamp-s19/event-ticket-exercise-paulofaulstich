pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;

    uint constant PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        bool isOpen;
        mapping (address => uint) buyers;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) public events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner () {
        require(msg.sender == owner, "It's not the owner");
        _;
    }

    constructor() public {
        /* Set the owner to the creator of this contract */
        owner = msg.sender;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory description, string memory url, uint numberOfTickets)
        public
        onlyOwner
    {
        events[idGenerator] = Event(description, url, numberOfTickets, 0, true);
        emit LogEventAdded(description, url, numberOfTickets, idGenerator);
        idGenerator++;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint eventID)
        public
        view
        returns (string memory description, string memory url, uint ticketsAvailable, uint sales, bool isOpen)
    {
        return (
            events[eventID].description,
            events[eventID].website,
            events[eventID].totalTickets,
            events[eventID].sales,
            events[eventID].isOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint eventID, uint numberOfTickets)
        public
        payable
    {
        Event storage e = events[eventID];

        require(e.isOpen, "The event is not opened");
        require(msg.value >= numberOfTickets * PRICE_TICKET, "Insufficient value for the purchase");
        require(numberOfTickets <= e.totalTickets - e.sales, "Tickets Sold out");


        uint _price = numberOfTickets * PRICE_TICKET;

        e.buyers[msg.sender] += numberOfTickets;
        e.sales += numberOfTickets;

        uint amountToRefund = msg.value - _price;
        msg.sender.transfer(amountToRefund);

        emit LogBuyTickets(msg.sender, eventID, numberOfTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint eventID)
        public
    {
        Event storage e = events[eventID];

        uint ticketsPurchased = e.buyers[msg.sender];
        require(ticketsPurchased > 0, "You don't have any tickets");
        e.sales -= ticketsPurchased;
        msg.sender.transfer(ticketsPurchased * PRICE_TICKET);

        emit LogGetRefund(msg.sender, eventID, ticketsPurchased);
    }


    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint eventID)
        public
        view
        returns(uint numberOfTickets)
    {
        return events[eventID].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint eventID)
        public
        onlyOwner
    {
        uint balance = events[eventID].sales * PRICE_TICKET;

        events[eventID].isOpen = false;
        owner.transfer(balance);
        emit LogEndSale(owner, balance, eventID);
    }

}
