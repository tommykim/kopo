pragma solidity >=0.4.22 <0.7.0;

contract Vote{
    
    struct Proposal {
        address owner;
        string name; 
        uint voteCount; 
    }
    
    struct Voter {
        bool voted;  
        uint vote;   
    }
    

    event voted(address voter, uint proposal);

    mapping(address => Voter) voters;

    Proposal[] proposals;
    function createProposal(string _name) public {
            proposals.push(Proposal({
                owner:  msg.sender,
                name: _name,
                voteCount: 0
            }));
    }
    
    function getProposal( uint proposal) public view returns (string , uint){       
        return (proposals[proposal].name,proposals[proposal].voteCount);
    }

    
    function vote(uint proposal) public{
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);
        require(proposals[proposal].owner != msg.sender);
        sender.voted = true;
        sender.vote = proposal;
        emit voted(msg.sender, proposal);
        proposals[proposal].voteCount += 1;
    }



}