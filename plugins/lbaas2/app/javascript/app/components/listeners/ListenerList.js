import React from 'react';
import { useEffect, useState } from 'react'
import useListener from '../../../lib/hooks/useListener'
import {DefeatableLink} from 'lib/components/defeatable_link';
import ListenerItem from './ListenerItem'
import queryString from 'query-string'
import { Link } from 'react-router-dom';
import L7PolicyList from '../l7policies/L7PolicyList'
import HelpPopover from '../shared/HelpPopover'
import { CSSTransition, TransitionGroup } from 'react-transition-group';
import { useGlobalState } from '../StateProvider'

const TableFadeTransition = ({
  children,
  ...props
}) => (<CSSTransition {...props} timeout={200} unmountOnExit classNames="css-transition-fade">
  {children}
</CSSTransition>);


const ListenerList = ({props, loadbalancerID}) => {
  const {persistListeners} = useListener()
  const state = useGlobalState().listeners
  const [searchTerm, setSearchTerm] = useState(null)
  const [selectedID, setSelectedID] = useState(null)

  useEffect(() => { 
    console.log('LISTENER INITIAL FETCH')
    // no add marker so we get always the first ones on lading component
    persistListeners(loadbalancerID, null).then((data) => {
      selectListener()
    }).catch( error => {
      // TODO
    })
  }, [loadbalancerID]);

  const selectListener = () => {
    const values = queryString.parse(props.location.search)
    const id = values.listener

    if (id) {
      // Listener was selected
      setSelectedID(id)
      // filter the listener list to show just the one item
      setSearchTerm(id)
    } else {
      // NOT FOUND
    }
  }

  const onSelectListener = (listenerID) => {
    const id = listenerID || ""
    const pathname = props.location.pathname; 
    const searchParams = new URLSearchParams(props.location.search); 
    searchParams.set("listener", id);
    props.history.push({
      pathname: pathname,
      search: searchParams.toString()
    })
    // Listener was selected
    setSelectedID(listenerID)
    // filter the listener list to show just the one item
    setSearchTerm(listenerID)
  }

  // const loadNext = event => {
  //   if(!state.isLoading && state.hasNext) {
  //     fetchListeners(loadbalancerID, state.marker)
  //   }
  // }

  const restoreUrl = (e) => {
    if (e) {
      e.stopPropagation()
      e.preventDefault()
    }
    onSelectListener()
  }

  const error = state.error
  const hasNext = state.hasNext
  const items = state.items

  const filterItems = (searchTerm, items) => {
    if(!searchTerm) return items;
    // filter items      
    if (selectedID) {
      return items.filter((i) =>
        i.id == searchTerm.trim()
      )
    } else {
      const regex = new RegExp(searchTerm.trim(), "i");
      return items.filter((i) =>
      `${i.id} ${i.name} ${i.description}`.search(regex) >= 0
    )
    }
  }

  const getSelectedItem = (selectedID, items) => {
    if (selectedID) {
      const found =  filterItems(selectedID, items)
      if (found.length == 1) {
        return found[0]
      }
    } 
    return null
  }

  console.log("RENDER Listener list")

  const selectedItem = getSelectedItem(selectedID, items)
  const listeners =  filterItems(searchTerm, items)
  const isLoading = state.isLoading
  return ( 
    <div className="details-section">
      <div className="display-flex">
        <h4>Listeners</h4>
        <HelpPopover text="Object representing the listening endpoint of a load balanced service. TCP / UDP port, as well as protocol information and other protocol- specific details are attributes of the listener. Notably, though, the IP address is not." />
      </div>
      {error ?
        <ErrorPage headTitle="Load Balancers Listeners" error={error}/>
        :
        <React.Fragment>

          <div className='toolbar'>
            { selectedID &&
              <Link className="back-link" to="#" onClick={restoreUrl}>
                <i className="fa fa-chevron-circle-left"></i>
                Back to Listeners
              </Link>
            }
            <div className="main-buttons">
              {!selectedID &&
                <DefeatableLink
                  disabled={isLoading}
                  to='/listeners/new'
                  className='btn btn-primary'>
                  New Listener
                </DefeatableLink>
              }
            </div>
          </div>
          
          <TransitionGroup>
            <TableFadeTransition key={listeners.length}>
              <table className={selectedID ? "table table-section listeners" : "table table-hover listeners"}>
                <thead>
                    <tr>
                        <th>Name/ID</th>
                        <th>Description</th>
                        <th>State</th>
                        <th>Prov. Status</th>
                        <th>Tags</th>
                        <th>Protocol</th>
                        <th>Protocol Port</th>
                        <th>Default Pool</th>
                        <th>Connection Limit</th>
                        <th>#L7 Policies</th>
                        <th className='snug'></th>
                    </tr>
                </thead>
                <tbody>
                  {listeners && listeners.length>0 ?
                    listeners.map( (listener, index) =>
                      <ListenerItem 
                      listener={listener} 
                      searchTerm={searchTerm} 
                      key={index} 
                      onSelectListener={onSelectListener}
                      disabled={selectedID ? true : false}
                      />
                    )
                    :
                    <tr>
                      <td colSpan="11">
                        { isLoading ? <span className='spinner'/> : 'No listeners found.' }
                      </td>
                    </tr>  
                  }
                </tbody>
              </table>
            </TableFadeTransition>
          </TransitionGroup>

          {selectedItem &&
            <L7PolicyList props={props} loadbalancerID={loadbalancerID} listener={selectedItem}/>
          }

          </React.Fragment>
      }
    </div>
   );
}
 
export default ListenerList