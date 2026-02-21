// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// CONTRACT 1: SchoolToken (The ERC20 Token)
contract SchoolToken {
    string public constant name = "SchoolToken";
    string public constant symbol = "SCH";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    error NotOwner(address caller);
    error ZeroAddress();
    error InsufficientBalance(uint256 available, uint256 required);
    error InsufficientAllowance(uint256 available, uint256 required);
    error NoETHToSend();
    error ETHTransferFailed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        _;
    }

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        // FIX: Account for decimals so 1 = 1 full token, not 1 wei
        _mint(msg.sender, _initialSupply * 10 ** decimals);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        if (recipient == address(0)) revert ZeroAddress();
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance(balanceOf[msg.sender], amount);

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        if (spender == address(0)) revert ZeroAddress();
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if (recipient == address(0)) revert ZeroAddress();
        if (allowance[sender][msg.sender] < amount) {
            revert InsufficientAllowance(allowance[sender][msg.sender], amount);
        }
        if (balanceOf[sender] < amount) revert InsufficientBalance(balanceOf[sender], amount);

        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function buyTokens() public payable {
        if (msg.value == 0) revert NoETHToSend();

        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;

        emit Transfer(address(0), msg.sender, msg.value);
    }

    function sellTokens(uint256 amount) public {
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance(balanceOf[msg.sender], amount);

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert ETHTransferFailed();

        emit Transfer(msg.sender, address(0), amount);
    }

    // FIX: Removed the public `mint` function to prevent the owner from
    // printing unbacked tokens and stealing ETH via `sellTokens`.

    function _mint(address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddress();
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}

// CONTRACT 2: SchoolManager (The Logic Contract)
contract SchoolManager {
    // FIX: Made these immutable to save gas since they never change
    SchoolToken public immutable token;
    address public immutable principal;

    struct Student {
        string name;
        uint256 level;
        bool hasPaid;
        uint256 paymentTimestamp;
    }

    struct Staff {
        string name;
        uint256 salary;
        bool isRegistered;
    }

    mapping(address => Student) public students;
    mapping(address => Staff) public staffRecords;

    // Using private for arrays is standard practice; users can query via standard getters or getAll()
    address[] private studentList;
    address[] private staffList;

    error NotPrincipal(address caller);
    error InvalidLevel(uint256 level);
    error AlreadyRegistered();
    error PaymentFailed();
    error StaffNotRegistered();

    modifier onlyPrincipal() {
        if (msg.sender != principal) revert NotPrincipal(msg.sender);
        _;
    }

    constructor(address _tokenAddress) {
        token = SchoolToken(_tokenAddress);
        principal = msg.sender;
    }

    function _getFeeForLevel(uint256 level) internal pure returns (uint256) {
        if (level == 100) return 10 * 10 ** 18;
        if (level == 200) return 20 * 10 ** 18;
        if (level == 300) return 30 * 10 ** 18;
        if (level == 400) return 40 * 10 ** 18;
        revert InvalidLevel(level);
    }

    function registerStudent(string memory _name, uint256 _level) external {
        if (students[msg.sender].hasPaid) revert AlreadyRegistered();

        uint256 fee = _getFeeForLevel(_level);

        // NOTE: The student MUST call `approve()` on the Token contract first,
        // allowing this Manager contract to spend their tokens.
        bool success = token.transferFrom(msg.sender, address(this), fee);
        if (!success) revert PaymentFailed();

        students[msg.sender] = Student({name: _name, level: _level, hasPaid: true, paymentTimestamp: block.timestamp});

        studentList.push(msg.sender);
    }

    function getStudent(address _student)
        external
        view
        returns (string memory name, uint256 level, bool hasPaid, uint256 paymentTimestamp)
    {
        Student memory s = students[_student];
        return (s.name, s.level, s.hasPaid, s.paymentTimestamp);
    }

    function getAllStudents() external view returns (address[] memory) {
        return studentList;
    }

    function registerStaff(address _staff, string memory _name, uint256 _salary) external onlyPrincipal {
        if (staffRecords[_staff].isRegistered) revert AlreadyRegistered();

        staffRecords[_staff] = Staff({name: _name, salary: _salary, isRegistered: true});

        staffList.push(_staff);
    }

    function payStaff(address _staff) external onlyPrincipal {
        Staff memory s = staffRecords[_staff];
        if (!s.isRegistered) revert StaffNotRegistered();

        bool success = token.transfer(_staff, s.salary);
        if (!success) revert PaymentFailed();
    }

    function getSchoolBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
