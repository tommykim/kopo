pragma solidity ^0.4.21;

contract PubicAuction {
    // 옥션의 파라미터. 시간은 아래 둘중 하나입니다.
    // 앱솔루트 유닉스 타임스탬프 (seconds since 1970-01-01)
    // 혹은 시한(time period) in seconds.
    address public beneficiary;
    uint public auctionEnd;

    // 옥션의 현재 상황.
    address public highestBidder;
    uint public highestBid;

    // 이전 가격 제시들의 수락된 출금.
    mapping(address => uint) pendingReturns;

    // 마지막에 true 로 설정, 어떠한 변경도 허락되지 않습니다.
    bool ended;

    // 변경에 발생하는 이벤트
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // 아래의 것은 소위 "natspec"이라고 불리우는 코멘트,
    // 3개의 슬래시에 의해 알아볼 수 있습니다.
    // 이것을 유저가 트렌젝션에 대한 확인을 요청 받을때
    // 보여집니다.

    /// 수혜자의 주소를 대신하여 두번째 가격제시 기간 '_biddingTime'과
    /// 수혜자의 주소 '_beneficiary' 를 포함하는
    /// 간단한 옥션을 제작합니다.
    function SimpleAuction(
        uint _biddingTime,
        address _beneficiary
    ) public {
        beneficiary = _beneficiary;
        auctionEnd = now + _biddingTime;
    }

    /// 경매에 대한 가격제시와 값은
    /// 이 transaction과 함께 보내집니다.
    /// 값은 경매에서 이기지 못했을 경우만
    /// 반환 받을 수 있습니다.
    function bid() public payable {
        // 어떤 인자도 필요하지 않음, 모든
        // 모든 정보는 이미 트렌젝션의
        // 일부이다. 'payable' 키워드는
        // 이더를 지급는 것이 가능 하도록
        // 하기 위하여 함수에게 요구됩니다.

        // 경매 기간이 끝났으면
        // 되돌아 갑니다.
        require(now <= auctionEnd);

        // 만약 이 가격제시가 더 높지 않다면, 돈을
        // 되돌려 보냅니다.
        require(msg.value > highestBid);

        if (highestBid != 0) {
            // 간단히 highestBidder.send(highestBid)를 사용하여
            // 돈을 돌려 보내는 것은 보안상의 리스크가 있습니다.
            // 그것은 신뢰되지 않은 콘트렉트를 실행 시킬수 있기 때문입니다.
            // 받는 사람이 그들의 돈을 그들 스스로 출금 하도록 하는 것이
            // 항상 더 안전합니다.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// 비싸게 값이 불러진 가격제시 출금.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // 받는 사람이 이 `send` 반환 이전에 받는 호출의 일부로써
            // 이 함수를 다시 호출할 수 있기 때문에
            // 이것을 0으로 설정하는 것은 중요하다.
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // 여기서 throw를 호출할 필요가 없습니다, 빚진 양만 초기화.
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// 이 경매를 끝내고 최고 가격 제시를
    /// 수혜자에게 송금.
    function auctionEnd() public {

        // 이것은 다른 콘트렉트와 상호작용하는 함수의 구조를 잡는 좋은 가이드 라인입니다.
        // (i.e. 그것들은 이더를 보내거나 함수를 호출합니다.)
        // 3가지 단계:
        // 1. 조건을 확인
        // 2. 동작을 수행  (잠재적으로 변경되는 조건)
        // 3. interacting with other contracts
        // If these phases are mixed up, the other contract could call
        // back into the current contract and modify the state or cause
        // effects (ether payout) to be performed multiple times.
        // If functions called internally include interaction with external
        // contracts, they also have to be considered interaction with
        // external contracts.

        // 1. 조건
        require(now >= auctionEnd); // auction did not yet end
        require(!ended); // this function has already been called

        // 2. 영향
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. 상호작용
        beneficiary.transfer(highestBid);
    }
}
