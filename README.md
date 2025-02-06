# Medical Record Smart Contract

This Solidity smart contract manages medical records on a blockchain, providing secure data storage, granular access control, and a doctor verification mechanism.  It leverages IPFS for off-chain storage of the actual document content, while metadata is stored on-chain.

## Table of Contents

*   Functionalities
*   Special Features
*   Contract Structure
*   Security Considerations
*   Deployment
*   Testing

## Functionalities

1.  **Patient Registration:** Administrators can register new patients, providing their name and the IPFS hash of their photo. Patient data (name, photo hash) is stored securely on the blockchain.

2.  **Doctor Registration:** Administrators can register new doctors, including their name, BMDC registration number, and the IPFS hash of their photo.

3.  **Doctor Verification:** A designated backend service (external to this contract - we have scrap BM&DC website with puppeteer) can verify doctors' credentials and mark them as verified on the blockchain. This allows patients to trust the doctors listed on the platform.

4.  **Document Upload:** Registered patients can upload their medical documents by providing the IPFS hash of the document and a document type.  The document itself is stored off-chain (IPFS), while its metadata (IPFS hash, type, timestamp, uploader) is stored on the blockchain.

5.  **Access Granting/Revoking:** Patients have granular control over who can access their documents. They can grant or revoke access to specific doctors.

6.  **Document Retrieval:** Doctors with granted access can retrieve the metadata of a patient's document (including the IPFS hash) to then fetch the actual document from IPFS.

7.  **Document Deletion:** Patients can delete their own documents. Doctors with access can also delete documents.

8.  **Patient Data Deletion:** Administrators can delete patient records, including all associated documents and access permissions.

9.  **Doctor Data Deletion/Role Revocation:** Administrators can delete doctor records or revoke their roles. This removes the doctor's information from the blockchain and revokes their access to all patient documents.

10. **Data Retrieval:** Patients can view a list of their uploaded documents, including their types and timestamps. Doctors can get a list of all verified doctors. Photo hashes for patients and doctors can be retrieved.

## Special Features

1.  **Secure Data Storage:** Patient and doctor data, document metadata, and access permissions are stored securely on the blockchain, ensuring immutability and transparency.

2.  **Off-Chain Document Storage:** The actual medical documents are stored off-chain (e.g., IPFS) to manage the size and cost of blockchain storage. Only the document metadata (IPFS hash, type, etc.) is stored on-chain.

3.  **Granular Access Control:** Patients have fine-grained control over document access, enhancing privacy.

4.  **Role-Based Access:** The contract uses modifiers (`onlyAdmin`, `onlyBackend`) to restrict access to sensitive functions, ensuring only authorized entities can perform administrative or backend operations.

5.  **Efficient Access Checks:** The `doctorDocumentAccess` mapping is used for efficient access checks.

6.  **Doctor Verification:** The doctor verification mechanism adds a layer of trust and credibility to the platform.

7.  **Event Emission:** The contract emits events for all significant actions, allowing for off-chain monitoring and logging.

8.  **Patient and Doctor Lists:** The contract maintains separate lists of patient and verified doctor addresses to enable iteration and efficient data retrieval. This is crucial because Solidity does not allow direct iteration over mappings.

9.  **Safe Array Removal:** The contract uses a dedicated `removeFromArray` function to safely and correctly remove elements from arrays, preventing potential issues with standard array `pop()` function usage.

## Contract Structure

The contract is structured into several sections:

*   **State Variables:** Defines all the data stored on the blockchain, including mappings for patient/doctor data, documents, access permissions, and lists for verified doctors and patients.

*   **Events:** Defines the events emitted by the contract when important actions occur (e.g., patient registration, document upload, access grant/revoke).

*   **Modifiers:** Defines access control restrictions (`onlyAdmin`, `onlyBackend`).

*   **Constructor:** Initializes the contract, setting the deployer as the initial admin.

*   **Functions:** Implements all the contract's logic, including registration, document management, data retrieval, and deletion functions.

## Security Considerations

*   **Access Control:** The contract implements role-based access control using modifiers to restrict access to sensitive functions.  However, the security of the backend service responsible for doctor verification is crucial.  Compromise of the backend could allow unauthorized verification of doctors.

*   **Data Validation:** While the contract includes some basic data validation (e.g., checking for existing registrations), more robust validation might be necessary depending on the specific requirements.  Consider validating IPFS hashes and document types.

*   **Reentrancy Attacks:**  The contract, as currently written, is not vulnerable to reentrancy attacks because it doesn't involve external calls to other contracts.  However, if you add functionality that makes external calls, you'll need to implement reentrancy protection mechanisms.

*   **IPFS Security:**  The security of the documents stored on IPFS depends on the IPFS network itself.  Consider the implications of IPFS content addressing and potential data availability issues.

## Deployment

1.  **Environment Setup:** Use a development environment like Hardhat or Truffle.

2.  **Compilation:** Compile the contract using `npx hardhat compile` (or the equivalent command for your environment).

3.  **Deployment Script:** Write a deployment script to deploy the contract to your chosen network (e.g., a local Hardhat network, a testnet, or mainnet).

4.  **Deployment:** Deploy the contract using the deployment script.  Note down the deployed contract address.

## Testing

1.  **Test Environment:** Use a testing framework like Hardhat or Truffle.

2.  **Test Cases:** Write comprehensive test cases for each function in the contract, covering various scenarios, including edge cases and error conditions.

3.  **Assertions:** Use an assertion library like Chai to verify the expected behavior of the contract in your tests.

4.  **Test Execution:** Run the tests using `npx hardhat test` (or the equivalent command).  Ensure all tests pass.
