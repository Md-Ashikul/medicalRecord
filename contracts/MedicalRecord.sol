// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "hardhat/console.sol";

contract MedicalRecord {
    address public admin;
    mapping(address => string) public patientNames;
    mapping(address => string) public doctorNames;
    mapping(uint => address) public doctorByBmdc;
    mapping(address => bool) public doctorVerified;
    mapping(bytes32 => Document) public documents;
    mapping(bytes32 => mapping(address => bool)) public documentAccess;
    mapping(address => mapping(bytes32 => bool)) public doctorDocumentAccess;
    address public backendAddress;
    mapping(address => bytes32[]) public patientDocuments;
    mapping(address => bytes32) public patientPhotoHashes;
    mapping(address => bytes32) public doctorPhotoHashes;
    mapping(bytes32 => address[]) public doctorsWithAccess;

    address[] public verifiedDoctors;
    mapping(address => bool) public isVerifiedDoctor;
    address[] public patientList; // New: List of all patients

    struct Document {
        bytes32 ipfsHash;
        string documentType;
        uint timestamp;
        address uploader;
    }

    // ... (Events - Step 2)---------------------------------------------------------------------------------------------------------

    event PatientRegistered(
        address patientAddress,
        string name,
        bytes32 photoHash
    );
    event DoctorRegistered(
        address doctorAddress,
        string name,
        uint bmdcRegistrationNumber,
        bytes32 photoHash
    );
    event DoctorVerified(uint bmdcRegistrationNumber, bool isVerified);
    event DocumentUploaded(
        bytes32 ipfsHash,
        string documentType,
        uint timestamp,
        address patientAddress
    );
    event AccessGranted(
        bytes32 ipfsHash,
        address doctorAddress,
        address patientAddress
    );
    event AccessRevoked(
        bytes32 ipfsHash,
        address doctorAddress,
        address patientAddress
    );
    event BackendAddressSet(address backendAddress);
    event DocumentDeleted(bytes32 ipfsHash);
    event PatientDeleted(address patientAddress);
    event DoctorDeleted(address doctorAddress);
    event DoctorRoleRevoked(address doctorAddress, bool wasVerified);
    event MyRecordDeleted(bytes32 ipfsHash);

    // ... (Modifiers - Step 3)-----------------------------------------------------------------------------------------------------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyBackend() {
        require(
            msg.sender == backendAddress,
            "Only backend can call this function"
        );
        _;
    }

    // ... (Constructor - Step 4)--------------------------------------------------------------------------------------------------

    constructor() {
        admin = msg.sender;
    }

    // ... (Registration/Verification - Step 5)------------------------------------------------------------------------------------

    function removeFromArray(bytes32[] storage arr, bytes32 item) internal {
        uint length = arr.length;
        for (uint i = 0; i < length; i++) {
            if (arr[i] == item) {
                arr[i] = arr[length - 1];
                arr.pop();
                return;
            }
        }
    }

    function registerPatient(
        address _patientAddress,
        string memory _name,
        bytes32 _photoHash
    ) public onlyAdmin {
        require(
            bytes(patientNames[_patientAddress]).length == 0,
            "Patient already registered"
        );
        patientNames[_patientAddress] = _name;
        patientPhotoHashes[_patientAddress] = _photoHash;
        patientList.push(_patientAddress); // Add to patient list
        emit PatientRegistered(_patientAddress, _name, _photoHash);
    }

    function registerDoctor(
        address _doctorAddress,
        string memory _name,
        uint _bmdcRegistrationNumber,
        bytes32 _photoHash
    ) public onlyAdmin {
        require(
            doctorByBmdc[_bmdcRegistrationNumber] == address(0),
            "Doctor with this BMDC already registered"
        );
        doctorNames[_doctorAddress] = _name;
        doctorByBmdc[_bmdcRegistrationNumber] = _doctorAddress;
        doctorPhotoHashes[_doctorAddress] = _photoHash;
        emit DoctorRegistered(
            _doctorAddress,
            _name,
            _bmdcRegistrationNumber,
            _photoHash
        );
    }

    function setBackendAddress(address _backendAddress) public onlyAdmin {
        backendAddress = _backendAddress;
        emit BackendAddressSet(_backendAddress);
    }

    function verifyDoctor(
        uint _bmdcRegistrationNumber,
        bool _isVerified
    ) public onlyBackend {
        address doctorAddress = doctorByBmdc[_bmdcRegistrationNumber];
        require(doctorAddress != address(0), "Doctor not found");
        doctorVerified[doctorAddress] = _isVerified;
        emit DoctorVerified(_bmdcRegistrationNumber, _isVerified);

        if (_isVerified && !isVerifiedDoctor[doctorAddress]) {
            verifiedDoctors.push(doctorAddress);
            isVerifiedDoctor[doctorAddress] = true;
        } else if (!_isVerified && isVerifiedDoctor[doctorAddress]) {
            for (uint i = 0; i < verifiedDoctors.length; i++) {
                if (verifiedDoctors[i] == doctorAddress) {
                    verifiedDoctors[i] = verifiedDoctors[
                        verifiedDoctors.length - 1
                    ];
                    verifiedDoctors.pop();
                    break;
                }
            }
            isVerifiedDoctor[doctorAddress] = false;
        }
    }

    // ... (Document Management - Step 6)----------------------------------------------------------------------------------------

    function uploadDocument(
        bytes32 _ipfsHash,
        string memory _documentType
    ) public {
        require(
            bytes(patientNames[msg.sender]).length > 0,
            "Only registered patients can upload documents"
        );
        documents[_ipfsHash] = Document(
            _ipfsHash,
            _documentType,
            block.timestamp,
            msg.sender
        );
        patientDocuments[msg.sender].push(_ipfsHash);
        emit DocumentUploaded(
            _ipfsHash,
            _documentType,
            block.timestamp,
            msg.sender
        );
    }

    function grantAccess(address _doctorAddress, bytes32 _ipfsHash) public {
        require(
            documents[_ipfsHash].uploader == msg.sender,
            "You don't own this document"
        );
        documentAccess[_ipfsHash][_doctorAddress] = true;
        doctorDocumentAccess[_doctorAddress][_ipfsHash] = true;
        doctorsWithAccess[_ipfsHash].push(_doctorAddress);
        emit AccessGranted(_ipfsHash, _doctorAddress, msg.sender);
    }

    function revokeAccess(address _doctorAddress, bytes32 _ipfsHash) public {
        require(
            documents[_ipfsHash].uploader == msg.sender,
            "You don't own this document"
        );
        documentAccess[_ipfsHash][_doctorAddress] = false;
        doctorDocumentAccess[_doctorAddress][_ipfsHash] = false;

        address[] storage doctorList = doctorsWithAccess[_ipfsHash];
        for (uint i = 0; i < doctorList.length; i++) {
            if (doctorList[i] == _doctorAddress) {
                doctorList[i] = doctorList[doctorList.length - 1];
                doctorList.pop();
                break;
            }
        }

        emit AccessRevoked(_ipfsHash, _doctorAddress, msg.sender);
    }

    function getDocument(
        bytes32 _ipfsHash
    )
        public
        view
        returns (
            bytes32 ipfsHash,
            string memory documentType,
            uint timestamp,
            address uploader
        )
    {
        require(
            documents[_ipfsHash].uploader != address(0), // Ensure document exists
            "Document does not exist"
        );

        require(
            msg.sender == documents[_ipfsHash].uploader ||
                doctorDocumentAccess[msg.sender][_ipfsHash],
            "Access denied"
        );

        Document storage doc = documents[_ipfsHash];
        return (doc.ipfsHash, doc.documentType, doc.timestamp, doc.uploader);
    }

    function deleteDocument(bytes32 _ipfsHash) public {
        require(
            documents[_ipfsHash].uploader == msg.sender,
            "You don't own this document"
        );
        address patient = documents[_ipfsHash].uploader;
        delete documents[_ipfsHash];

        removeFromArray(patientDocuments[patient], _ipfsHash);

        address[] storage doctorList = doctorsWithAccess[_ipfsHash];
        for (uint i = 0; i < doctorList.length; i++) {
            address doctor = doctorList[i];
            delete documentAccess[_ipfsHash][doctor];
            delete doctorDocumentAccess[doctor][_ipfsHash];
        }
        delete doctorsWithAccess[_ipfsHash];

        emit DocumentDeleted(_ipfsHash);
    }

    function deletePatientRecordByDoctor(bytes32 _ipfsHash) public {
        require(
            documents[_ipfsHash].uploader != address(0),
            "Document doesn't exist"
        );
        require(
            documentAccess[_ipfsHash][msg.sender],
            "Doctor does not have access to this document"
        );
        require(
            msg.sender != documents[_ipfsHash].uploader,
            "Patient can't delete the document through this function"
        );

        address patient = documents[_ipfsHash].uploader;
        delete documents[_ipfsHash];

        removeFromArray(patientDocuments[patient], _ipfsHash); // Use the new function

        address[] storage doctorList = doctorsWithAccess[_ipfsHash];
        for (uint i = 0; i < doctorList.length; i++) {
            address doctor = doctorList[i];
            delete documentAccess[_ipfsHash][doctor];
            delete doctorDocumentAccess[doctor][_ipfsHash];
        }
        delete doctorsWithAccess[_ipfsHash];

        emit DocumentDeleted(_ipfsHash);
    }

    // ... (Data Retrieval/Deletion - Step 7)----------------------------------------------------------------------------------

    function getPatientDocuments(
        address _patientAddress
    )
        public
        view
        returns (
            bytes32[] memory ipfsHashes,
            string[] memory documentTypes,
            uint[] memory timestamps
        )
    {
        require(
            msg.sender == _patientAddress,
            "You can only view your own documents"
        );
        bytes32[] storage hashes = patientDocuments[_patientAddress];
        uint length = hashes.length;

        bytes32[] memory _ipfsHashes = new bytes32[](length);
        string[] memory _documentTypes = new string[](length);
        uint[] memory _timestamps = new uint[](length);

        for (uint i = 0; i < length; i++) {
            Document storage doc = documents[hashes[i]];
            _ipfsHashes[i] = doc.ipfsHash;
            _documentTypes[i] = doc.documentType;
            _timestamps[i] = doc.timestamp;
        }

        return (_ipfsHashes, _documentTypes, _timestamps);
    }

    function deletePatient(address _patientAddress) public onlyAdmin {
        require(
            bytes(patientNames[_patientAddress]).length != 0,
            "Patient not registered"
        );

        // Remove from patientList:
        for (uint i = 0; i < patientList.length; i++) {
            if (patientList[i] == _patientAddress) {
                patientList[i] = patientList[patientList.length - 1];
                patientList.pop();
                break;
            }
        }

        delete patientNames[_patientAddress];
        delete patientPhotoHashes[_patientAddress];

        bytes32[] storage hashes = patientDocuments[_patientAddress];

        for (uint i = hashes.length; i > 0; i--) {
            bytes32 ipfsHash = hashes[i - 1];

            // Correctly delete from documentAccess and doctorsWithAccess:
            address[] storage doctorList = doctorsWithAccess[ipfsHash];
            for (uint j = 0; j < doctorList.length; j++) {
                address doctor = doctorList[j];
                delete documentAccess[ipfsHash][doctor]; // Delete individual access entries
                delete doctorDocumentAccess[doctor][ipfsHash];
            }
            delete doctorsWithAccess[ipfsHash];

            delete documents[ipfsHash]; // Delete the document itself AFTER deleting access
            if (i < hashes.length) {
                hashes[i - 1] = hashes[hashes.length - 1];
            }
            hashes.pop();
        }

        delete patientDocuments[_patientAddress];
        emit PatientDeleted(_patientAddress);
    }

    function deleteDoctor(uint _bmdcRegistrationNumber) public onlyAdmin {
        address doctorAddress = doctorByBmdc[_bmdcRegistrationNumber];
        require(doctorAddress != address(0), "Doctor not found");
        delete doctorNames[doctorAddress];
        delete doctorPhotoHashes[doctorAddress];
        delete doctorByBmdc[_bmdcRegistrationNumber];
        doctorVerified[doctorAddress] = false;

        if (isVerifiedDoctor[doctorAddress]) {
            for (uint i = 0; i < verifiedDoctors.length; i++) {
                if (verifiedDoctors[i] == doctorAddress) {
                    verifiedDoctors[i] = verifiedDoctors[
                        verifiedDoctors.length - 1
                    ];
                    verifiedDoctors.pop();
                    break;
                }
            }
            isVerifiedDoctor[doctorAddress] = false;
        }

        for (uint i = 0; i < patientList.length; i++) {
            address patient = patientList[i];
            bytes32[] storage patientDocs = patientDocuments[patient];
            for (uint j = 0; j < patientDocs.length; j++) {
                bytes32 ipfsHash = patientDocs[j];
                if (doctorDocumentAccess[doctorAddress][ipfsHash]) {
                    delete documentAccess[ipfsHash][doctorAddress];
                    delete doctorDocumentAccess[doctorAddress][ipfsHash];

                    address[] storage doctorList = doctorsWithAccess[ipfsHash];
                    for (uint k = 0; k < doctorList.length; k++) {
                        if (doctorList[k] == doctorAddress) {
                            doctorList[k] = doctorList[doctorList.length - 1];
                            doctorList.pop();
                            break;
                        }
                    }
                }
            }
        }

        emit DoctorDeleted(doctorAddress);
    }

    function getPatientPhotoHash(
        address _patientAddress
    ) public view returns (bytes32) {
        return patientPhotoHashes[_patientAddress];
    }

    function getDoctorPhotoHash(
        address _doctorAddress
    ) public view returns (bytes32) {
        return doctorPhotoHashes[_doctorAddress];
    }

    function getVerifiedDoctors() public view returns (address[] memory) {
        return verifiedDoctors;
    }

    function revokeDoctorRole(address _doctorAddress) public onlyAdmin {
        require(
            bytes(doctorNames[_doctorAddress]).length != 0,
            "Doctor not registered"
        ); // Correct comparison
        delete doctorNames[_doctorAddress];
        doctorVerified[_doctorAddress] = false;

        bool wasVerified = isVerifiedDoctor[_doctorAddress];

        if (isVerifiedDoctor[_doctorAddress]) {
            for (uint i = 0; i < verifiedDoctors.length; i++) {
                if (verifiedDoctors[i] == _doctorAddress) {
                    verifiedDoctors[i] = verifiedDoctors[
                        verifiedDoctors.length - 1
                    ];
                    verifiedDoctors.pop();
                    break;
                }
                isVerifiedDoctor[_doctorAddress] = false;
            }
        }

        for (uint i = 0; i < patientList.length; i++) {
            address patient = patientList[i];
            bytes32[] storage patientDocs = patientDocuments[patient];
            for (uint j = 0; j < patientDocs.length; j++) {
                bytes32 ipfsHash = patientDocs[j];
                if (doctorDocumentAccess[_doctorAddress][ipfsHash]) {
                    delete documentAccess[ipfsHash][_doctorAddress];
                    delete doctorDocumentAccess[_doctorAddress][ipfsHash];

                    address[] storage doctorList = doctorsWithAccess[ipfsHash];
                    for (uint k = 0; k < doctorList.length; k++) {
                        if (doctorList[k] == _doctorAddress) {
                            doctorList[k] = doctorList[doctorList.length - 1];
                            doctorList.pop();
                            break;
                        }
                    }
                }
            }
        }

        emit DoctorRoleRevoked(_doctorAddress, wasVerified);
    }

    function deleteMyRecord(bytes32 _ipfsHash) public {
        require(
            documents[_ipfsHash].uploader == msg.sender,
            "You don't own this document"
        );

        delete documents[_ipfsHash];

        removeFromArray(patientDocuments[msg.sender], _ipfsHash);

        address[] storage doctorList = doctorsWithAccess[_ipfsHash];
        for (uint i = 0; i < doctorList.length; i++) {
            address doctor = doctorList[i];
            delete documentAccess[_ipfsHash][doctor];
            delete doctorDocumentAccess[doctor][_ipfsHash];
        }
        delete doctorsWithAccess[_ipfsHash];

        emit MyRecordDeleted(_ipfsHash);
    }
}
