pragma solidity ^0.4.17;

contract InsurancePolicy {

    struct Participant {
        address delegate;
        uint role; // 1: Vendor, 2: Holder, 3:Authority
    }

    struct Claim {
        uint256 claimNo;
        string description;
        uint lossValue;
        uint paidOut;
        bool confirmed;
    }

    string policyNo;

    address policyHolder;
    address policyVendor;
    address incidentAuthority;

    uint paidPremium;
    uint insuredAmount; // max insured amount

    mapping(address => Participant) participants;
    Claim[] claims;

    function InsurancePolicy(string policyNo_, address policyHolder_, address policyVendor_, address incidentAuthority_) payable public {
        policyNo = policyNo_;

        policyVendor = policyVendor_;
        participants[policyVendor] = Participant(policyVendor_, 1);

        policyHolder = policyHolder_;
        participants[policyHolder] = Participant(policyHolder_, 2);

        incidentAuthority = incidentAuthority_;
        participants[incidentAuthority] = Participant(incidentAuthority_, 3);

        paidPremium = 0;
    }

    function payPremium() payable public {
        // require (msg.sender == policyHolder); // onlyPolicyHolder
        uint premium = msg.value;
        // Send money to the contract --- it stays there!
        paidPremium += premium / 1000000000000000000; // In unit of Ether
    }

    function claimLoss(string description, uint lossValue) public returns (uint256) {
        // require (msg.sender == policyHolder); // onlyPolicyHolder
        // require (paidPremium > 0);

        uint256 claimNo = claims.length + 1;
        claims.push(Claim(claimNo, description, lossValue, 0, false));
        // TODO: Notify policyVendor and incidentAuthority

        return claimNo;
    }

    function confirmLoss(uint8 claimNo, uint lossValue) public returns (string) {
        // require (msg.sender == incidentAuthority); // onlyIncidentAuthority

        for (uint i=claims.length; i>0; --i) {
            if (claims[i-1].claimNo == claimNo) {
                if (claims[i-1].lossValue != lossValue) {
                    revert(); // "LOSS_UNMATCH"
                }

                claims[i-1].confirmed = true; // TODO: Notify policyVendor

                return "OK";
            }
        }

        revert(); //"CLAIM_NOT_FOUND"
    }

    function payForClaim(uint8 claimNo) payable public returns (string){
        // require (msg.sender == policyVendor); // onlyPolicyVendor
        uint paidOut = msg.value; // In unit of WEI

        for (uint i=claims.length; i>0; --i) {
            if (claims[i-1].claimNo == claimNo) {
                if (claims[i-1].confirmed == true) {
                    claims[i-1].paidOut = paidOut; // TODO: Notify policyHolder

                    return "OK";
                }
            }
        }

        return "CLAIM_NOT_FOUND";
    }

    function receivePayout() public returns (uint) {
        uint totalPaidOut = 0; // In unit of ether

        for (uint i=claims.length; i>0; i--) {
            if (claims[i-1].confirmed == true) {
                totalPaidOut += claims[i-1].paidOut;
                claims[i-1].paidOut = 0;
            }
        }

        if (totalPaidOut > 0) {
            policyHolder.transfer(totalPaidOut); // In unit of WEI
            // TODO: Notify policyVendor
        }

        return totalPaidOut;
    }

    function viewPayout() public returns (uint) {
        uint totalPaidOut = 0;

        for (uint i=claims.length; i>0; i--) {
            if (claims[i-1].confirmed == true) {
                totalPaidOut += claims[i-1].paidOut;
                claims[i-1].paidOut = 0;
            }
        }

        return totalPaidOut;
    }
}
