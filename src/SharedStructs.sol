// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

library SharedStructs {

  enum UserType {
    Solver,
    Validator,
    ModuleCreator,
    ResourceProvider,
    JobCreator,
    Admin
  }

  // we map addresses onto infomation about the user
  struct User {
    address userAddress;
    // the CID of information for this user
    string metadataCID;
    string url;
    UserType[] roles;
  }
}