pragma solidity ^0.4.24;

/**
 * The withMapping contract is designed to add dynamic collection functionality to target contracts.
 * It provides create, update, delete, and collection accessors to underlying entities. This particular
 * implementation requires data to be uint. 
 *
 * author: lodge (https://github.com/jlogelin)
 *
 */
contract withMapping {

    /**
     * EntityStruct structure
     *
     * Structure that contains the data/pointer tuple
     *
     */
    struct EntityStruct {
      uint entityData;
      uint listPointer;
    }

    // mapping of the pointers / entities
    mapping(uint => EntityStruct) public entityStructs;

    // the entity list
    uint[] public entityList;

    /**
     * isEntity function
     *
     * Public view function that checks for the existance of an entity in the list
     *
     * @param entityAddress the entity list pointer
     */
    function isEntity(uint entityAddress) public view returns(bool isIndeed) {
      if(entityList.length == 0) return false;
      return (entityList[entityStructs[entityAddress].listPointer] == entityAddress);
    }

    /**
     * size function
     *
     * Public view function that returns the length of the underlying list
     *
     */
    function size() public view returns(uint entityCount) {
      return entityList.length;
    }

    /**
     * add function
     *
     * Public function adds a new entity to the list
     *
     * @param entityAddress the entity list pointer
     * @param entityData the data to add
     */
    function add(uint entityAddress, uint entityData) internal returns(bool success) {
      // require(!isEntity(entityAddress), "Entity already exists in collection [ withMapping.add() ]");
      entityStructs[entityAddress].entityData = entityData;
      entityStructs[entityAddress].listPointer = entityList.push(entityAddress) - 1;
      return true;
    }

    /**
     * get function
     *
     * Public function that returns an entity at a certain address
     *
     * @param entityAddress the entity list pointer
     */
    function get(uint entityAddress) public view returns(uint) {
    	require(isEntity(entityAddress), "Entity does not exist in collection [ withMapping.get() ]");
      return entityStructs[entityAddress].entityData;
    }

    /**
     * getAt function
     *
     * Public function that returns an entity at a certain index
     *
     * @param index the entity index
     */
    function getAt(uint index) public view
      returns(uint artifactId, uint price)
    {
      artifactId = entityList[index];
      price = entityStructs[artifactId].entityData;
    }

    /**
     * update function
     *
     * Public function that replaces an entities value
     *
     * @param entityAddress the entity list pointer
     * @param entityData the data to update
     */
    function update(uint entityAddress, uint entityData) internal returns(bool success) {
      require(isEntity(entityAddress), "Entity does not exist in collection [ withMapping.update() ]");
      entityStructs[entityAddress].entityData = entityData;
      return true;
    }

    /**
     * remove function
     *
     * Public function that removes an entity from the collection
     *
     * @param entityAddress the entity list pointer
     */
    function remove(uint entityAddress) internal returns(bool success) {
      require(isEntity(entityAddress), "Entity does not exist in collection [ withMapping.remove() ]");
      uint rowToDelete = entityStructs[entityAddress].listPointer;
      uint keyToMove   = entityList[entityList.length-1];
      entityList[rowToDelete] = keyToMove;
      entityStructs[keyToMove].listPointer = rowToDelete;
      entityList.length--;
      return true;
    }

}