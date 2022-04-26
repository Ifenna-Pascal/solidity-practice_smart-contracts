// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Filestroage {
    string public name;
    uint public CountPublic;
    uint public countPrivate;

    // public file struct
    struct Publicfile {
        uint count;
        address owner;
        string ipfsHash;
        string status;
    }

    // private file struct
    struct Privatefile {
        uint count;
        string ipfsHash;
        string status;
    }

    // shared file struct
    struct sharedFile {
        address shared_by;
        string shared_hash;
    }

    // mapping of uint to public files
    mapping (uint => Publicfile) public publicfiles;
    // mapping of addresses to private files
    mapping (address => Privatefile[]) public privatefiles;
    // mapping of address to shared files
    mapping (address => sharedFile[]) public shared_files;

    // event for file creation
    event FileCreation( uint count, address owner, string hash, string status);
    // event to return public files
    event ReturnedFiles(string suucessMessage);
    // file sharing event
    event sharedEvent(address share_to, address shared_by, string hash);


    // initiates contructor
    constructor (string memory _name)
    {
        name = _name;
    }

    // modifier to ensure file isn't shared to owner
    modifier isSharer ( address _share_to, address _owner) {
        require( _share_to != address(0), "Actual address is required");
        require(_share_to != _owner, "can't share yo yourself");
        _;
    }

    // modifier to ensure shared file is a private file
    modifier isPresent (address _owner, string memory _hash) {
        require(privateFilePresent(_owner, _hash), "Private file not present");
        _; 
    } 

    // private function to ensure shared file is a private file
    function privateFilePresent( address _owner, string memory hash) private view returns (bool value) {
        bool result;
        Privatefile[] memory files = privatefiles[_owner];
        for( uint i=0; i<files.length; i++) {
            if(keccak256(abi.encodePacked(files[i].ipfsHash)) == keccak256(abi.encodePacked(hash))) {
                result = true;
            }else {
                result = false;
            }
        } 
        return result;
    }

    // function to create new files base on either public or private
    function addFile ( string memory _hash, string memory _status ) public {
      if(keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked("public"))) {
            CountPublic ++;
            publicfiles[CountPublic] = Publicfile( CountPublic, msg.sender, _hash, _status);
            emit FileCreation(CountPublic, msg.sender, _hash, _status );
        }
    else {
        countPrivate ++;
        privatefiles[msg.sender].push(Privatefile(countPrivate, _hash, _status));
        emit FileCreation(countPrivate, msg.sender, _hash, _status );
    }
    }

    // Retrieve all public ifles
    function retrievePublicFiles () public view returns(Publicfile[] memory) {
      Publicfile[] memory public_files = new Publicfile[] (CountPublic);
      for(uint i=0; i<CountPublic; i++) {
        Publicfile storage public_file = publicfiles[i];
            public_files[i] = public_file;
      }
      return public_files;
    }
    
    // retrieve private files for specific users
    function retrievePrivateVideos () public view returns (Privatefile[] memory) {
      return privatefiles[msg.sender];
    }

    // function to share files
    function shareFile ( address _share_to, string memory _hashed_file ) isSharer(_share_to, msg.sender) isPresent(msg.sender, _hashed_file) public {
      shared_files[_share_to].push(sharedFile(msg.sender, _hashed_file));
      emit sharedEvent(_share_to, msg.sender, _hashed_file);
    }

    // function to get files recieved by other users
    function getSharedFile() public view returns (sharedFile[] memory) {
      return shared_files[msg.sender];
    }
}